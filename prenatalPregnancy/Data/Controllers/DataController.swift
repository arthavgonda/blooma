//
//  DataController.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore
import UIKit
import CoreMotion

final class DataController: DataControllerBacking {
    let dateService: DateServiceProtocol
    let progressStoreService: ProgressStoreService
    let progressFirestoreService: ProgressFirestoreService
    let profileFirestoreService: ProfileFirestoreServiceProtocol
    let routineCacheService: RoutineCacheService
    let routineSnapshotService: RoutineSnapshotService
    let routineSnapshotFirestoreService: RoutineSnapshotFirestoreService
    let routineEngine: RoutineEngine
    let routineViewModel: RoutineViewModel
    let feedbackService: FeedbackService
    let authViewModel: AuthViewModel
    let profileViewModel: ProfileViewModel
    let insightsViewModel: InsightsViewModel
    let homeViewModel: HomeViewModel
#if DEBUG
    let debugSeedService: DebugSeedService
#endif

    var userProfile: UserProfile

    /// Set to true only after loadProfileFromFirestore() succeeds.
    /// All saveProfileToFirestore() calls are no-ops until this is true,
    /// preventing the midnight-refresh race that wiped user data (BUG-016).
    var isProfileLoaded: Bool = false

    var currentUserId: String? {
        didSet {
            guard oldValue != currentUserId else { return }
            if currentUserId == nil {
                // Logout path: stop the listener, wipe in-memory state, and
                // reset the profile-loaded flag so a subsequent login starts
                // from a clean slate and cannot save a stale profile.
                isProfileLoaded = false
                progressFirestoreService.stopProgressListener()
                progressStoreService.clearProgressState()
                clearRoutineState()
            }
            // NOTE: startProgressListener() is called explicitly by SceneDelegate
            // and the login path AFTER all data (profile + progress + snapshot) has
            // loaded. Starting it here would race against those loads.
        }
    }
    private var lastAccessedDayKey: String?
    private var activeActivityId: String?
    var latestHealthVitals: ActivityExecutionRecord?

    var progressStore: [String: ActivityExecutionRecord] {
        get { progressStoreService.progressStore }
        set { progressStoreService.progressStore = newValue }
    }

    private(set) var allActivities: [ActivityDefinition] = []
    private(set) var rotationHistory: [ActivityRotationRecord] = []

    private let db = Firestore.firestore()
    private var activitySchedule: ActivitySchedule?

    static let progressDidChangeNotification = Notification.Name("DataController.progressDidChangeNotification")

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        let dateService = DateService()
        self.dateService = dateService
        let progressStoreService = ProgressStoreService(dateService: dateService, backing: nil)
        self.progressStoreService = progressStoreService
        let progressFirestoreService = ProgressFirestoreService(db: Firestore.firestore(), coordinator: progressStoreService)
        self.progressFirestoreService = progressFirestoreService
        progressStoreService.firestoreEncoder = progressFirestoreService
        progressStoreService.progressFirestore = progressFirestoreService
        self.profileFirestoreService = ProfileFirestoreService(db: Firestore.firestore())
        self.routineCacheService = RoutineCacheService()
        self.routineSnapshotService = RoutineSnapshotService()
        self.routineSnapshotFirestoreService = RoutineSnapshotFirestoreService(db: Firestore.firestore())
        self.routineEngine = RoutineEngine(context: nil)
        self.routineViewModel = RoutineViewModel(
            engine: routineEngine,
            cache: routineCacheService,
            snapshotService: routineSnapshotService,
            snapshotFirestore: routineSnapshotFirestoreService,
            progressStore: progressStoreService,
            dateService: dateService,
            backing: nil
        )
        self.feedbackService = FeedbackService(
            progressStore: progressStoreService,
            progressFirestore: progressFirestoreService,
            dateService: dateService,
            backing: nil
        )
        self.authViewModel = AuthViewModel(
            db: Firestore.firestore(),
            profileFirestore: profileFirestoreService,
            dateService: dateService,
            backing: nil
        )
        self.profileViewModel = ProfileViewModel(
            dateService: dateService,
            progressStore: progressStoreService,
            backing: nil
        )
        self.insightsViewModel = InsightsViewModel(
            dateService: dateService,
            progressStore: progressStoreService
        )
        self.homeViewModel = HomeViewModel(
            dateService: dateService,
            progressStore: progressStoreService,
            insightsViewModel: insightsViewModel,
            routineViewModel: routineViewModel
        )
#if DEBUG
        self.debugSeedService = DebugSeedService(
            db: Firestore.firestore(),
            progressStore: progressStoreService,
            progressFirestore: progressFirestoreService,
            profileFirestore: profileFirestoreService,
            insightsViewModel: insightsViewModel,
            dateService: dateService,
            allActivities: ActivityLoader.loadActivities,
            backing: nil
        )
#endif
        self.allActivities = ActivityLoader.loadActivities()
        progressStoreService.attach(backing: self)
        routineEngine.attach(context: self)
        routineViewModel.attach(backing: self)
        feedbackService.attach(backing: self)
        authViewModel.attach(backing: self)
        profileViewModel.attach(backing: self)
        insightsViewModel.attach(dataSource: self)
        homeViewModel.attach(dataSource: self)
#if DEBUG
        debugSeedService.attach(backing: self)
#endif
    }

    deinit {
        progressFirestoreService.stopProgressListener()
    }

    func notifyProgressChanged() {
        NotificationCenter.default.post(name: Self.progressDidChangeNotification, object: self)
    }

    func appendRotationHistory(activityId: String, date: Date) {
        rotationHistory.append(ActivityRotationRecord(activityId: activityId, lastPerformedDate: date))
    }

    func invalidateTodayRoutine() {
        routineViewModel.invalidateTodayButKeepProgress()
    }

    /// Explicitly starts the Firestore real-time progress listener.
    /// Must be called AFTER profile, progress, and today's routine snapshot have
    /// all been loaded so the listener's first update doesn't race the initial load.
    func startProgressListener() {
        progressFirestoreService.startProgressListener()
    }

    func loadProgressFromFirestore(completion: @escaping () -> Void) {
        progressFirestoreService.loadProgressFromFirestore(completion: completion)
    }

    // MARK: - Routine Snapshot Pre-Fetch

    func loadTodayRoutineSnapshot(completion: @escaping () -> Void) {
        routineViewModel.preloadTodayRoutineFromFirestore(date: Date(), completion: completion)
    }

    func prepareTodayRoutineForHome(completion: @escaping ([RoutineType: [RoutineItem]]) -> Void) {
        routineViewModel.prepareRoutineForHome(date: Date(), completion: completion)
    }

    func clearRoutineState() {
        routineCacheService.clearAll()
        routineSnapshotService.clearAll()
    }

    func insightsStartWeek() -> Int { progressStoreService.insightsStartWeek() }
    func availableInsightWeeks() -> [Int] { progressStoreService.availableInsightWeeks() }
    func resetPregnancyProgressDayAnchor() { progressStoreService.resetPregnancyProgressDayAnchor() }
    func refreshPregnancyProgressIfNeeded(referenceDate: Date = Date()) {
        progressStoreService.refreshPregnancyProgressIfNeeded(referenceDate: referenceDate)
    }
    func secondsUntilNextISTMidnight(from date: Date = Date()) -> TimeInterval {
        dateService.secondsUntilNextISTMidnight(from: date)
    }
    func refreshProgressIndexesAfterProfileUpdate() {
        progressStoreService.refreshProgressIndexesAfterProfileUpdate()
    }
    func startOfDayInIST(for date: Date = Date()) -> Date { dateService.startOfDayInIST(for: date) }
    func currentISTWeekday() -> String { dateService.currentISTWeekday() }
    func currentISTHour() -> Int { dateService.currentISTHour() }

    func getRoutineItems(for type: RoutineType, date: Date) -> [RoutineItem] {
        lastAccessedDayKey = dateService.dayKey(date)
        return routineViewModel.getRoutineItems(for: type, date: date)
    }
    func getTodayRoutineSummary(for date: Date) -> [RoutineSession] {
        routineViewModel.getTodayRoutineSummary(for: date)
    }
    func mapDifficulty(_ value: String?) -> DifficultyLevel { routineViewModel.mapDifficulty(value) }

    func updateUserProfile(_ profile: UserProfile) {
        profileViewModel.updateUserProfile(profile, replacing: userProfile)
    }

    func loadProgress(for item: RoutineItem, date: Date) -> RoutineItemProgress {
        progressStoreService.loadProgress(for: item, date: date)
    }
    func saveProgress(for item: RoutineItem, elapsedSeconds: Int?, status: RoutineItemStatus, date: Date) {
        progressStoreService.saveProgress(for: item, elapsedSeconds: elapsedSeconds, status: status, date: date)
    }
    func markItemCompleted(_ item: inout RoutineItem, date: Date) {
        progressStoreService.markItemCompleted(&item, date: date)
    }
    func markItemSkipped(_ item: inout RoutineItem, date: Date) {
        progressStoreService.markItemSkipped(&item, date: date)
    }
}

extension DataController {
    func updateProgressVitals(
        for item: RoutineItem,
        date: Date,
        heartRate: Int?,
        peakHeartRate: Int?,
        spo2: Int?,
        peakSpo2: Int?,
        calories: Int?,
        steps: Int?,
        elapsedSeconds: Int?,
        status: RoutineItemStatus
    ) {
        progressStoreService.updateProgressVitals(
            for: item,
            date: date,
            heartRate: heartRate,
            peakHeartRate: peakHeartRate,
            spo2: spo2,
            peakSpo2: peakSpo2,
            calories: calories,
            steps: steps,
            elapsedSeconds: elapsedSeconds,
            status: status
        )
    }

    func getAllProgress() -> [ActivityExecutionRecord] { progressStoreService.getAllProgress() }
    func getProgress(for activityId: String) -> [ActivityExecutionRecord] {
        progressStoreService.getProgress(for: activityId)
    }

    func loadScheduleFromDisk() {
        print("Schedule disk load disabled; use Firestore")
    }
    
    func saveScheduleToDisk() {
        print("Schedule disk save disabled; use Firestore")
    }
    
    func updateSessionProgress(
        activityId: String,
        date: Date,
        steps: Int?,
        distance: Double?,
        heartRate: Int?
    ) {
        
        guard var schedule = activitySchedule else { return }
        
        let key = Self.formatter.string(from: date)
        
        for i in 0..<schedule.insights.count {
            for j in 0..<schedule.insights[i].weeks.count {
                for k in 0..<schedule.insights[i].weeks[j].days.count {
                    
                    if schedule.insights[i].weeks[j].days[k].dayKey == key {
                        
                        for s in 0..<schedule.insights[i].weeks[j].days[k].sessions.count {
                            
                            var session = schedule.insights[i].weeks[j].days[k].sessions[s]
                            
                            if session.id.contains(activityId) {
                                
                                // Update stats
                                session.stats = session.stats.map { metric in
                                    
                                    var updated = metric
                                    
                                    switch metric.title.lowercased() {
                                        
                                    case "steps":
                                        if let steps = steps {
                                            updated.value = "\(steps)"
                                        }
                                        
                                    case "distance":
                                        if let distance = distance {
                                            updated.value = String(format: "%.2f", distance)
                                        }
                                        
                                    default:
                                        break
                                    }
                                    
                                    return updated
                                }
                                
                                // Update vitals
                                if var vitals = session.vitals {
                                    vitals = vitals.map { metric in
                                        
                                        var updated = metric
                                        
                                        if metric.title.lowercased() == "heart rate",
                                           let hr = heartRate {
                                            updated.value = "\(hr)"
                                        }
                                        
                                        return updated
                                    }
                                    
                                    session.vitals = vitals
                                }
                                
                                // Save back
                                schedule.insights[i].weeks[j].days[k].sessions[s] = session
                            }
                        }
                    }
                }
            }
        }
        
        self.activitySchedule = schedule
        saveScheduleToFirestore()
        progressFirestoreService.saveProgressStatsToFirestore(
            activityId: activityId,
            date: date,
            steps: steps,
            distance: distance,
            heartRate: heartRate
        )
    }
    
    
    func saveScheduleToFirestore() {
        
        guard let userId = currentUserId,
              let schedule = activitySchedule else { return }
        
        do {
            let data = try JSONEncoder().encode(schedule)
            let json = try JSONSerialization.jsonObject(with: data)
            
            db.collection("users")
                .document(userId)
                .setData(["schedule": json], merge: true)
            
            print(" Firestore saved")
            
        } catch {
            print(" Firestore error:", error)
        }
    }
    
    func loadScheduleFromFirestore(completion: @escaping () -> Void) {
        guard let userId = currentUserId else {
            completion()
            return
        }
        
        db.collection("users")
            .document(userId)
            .getDocument { [weak self] snapshot, error in
                guard let self else {
                    completion()
                    return
                }
                
                if let data = snapshot?.data()?["schedule"] {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let decoded = try JSONDecoder().decode(ActivitySchedule.self, from: jsonData)
                            self.activitySchedule = decoded
                            print("Firestore loaded")
                        } catch {
                            print("Decode error:", error)
                        }
                        completion()
                    }
                } else {
                    completion()
                }
            }
    }
    
    func stopActivity(activityId: String, completion: @escaping () -> Void) {
        
        guard activeActivityId == activityId else {
            completion()
            return
        }
        
        let end = Date()
        
        fetchTodayVitals { [weak self] vitals in
            
            //  NEW SYSTEM UPDATE
            self?.updateSessionProgress(
                activityId: activityId,
                date: end,
                steps: vitals.steps,
                distance: vitals.distanceMeters,
                heartRate: vitals.avgHeartRate
            )
            
            //  optional firestore sync
            self?.saveScheduleToFirestore()
            
            self?.activeActivityId = nil
            
            completion()
        }
    }
}

extension DataController {
    func loadAppContent(id: String) -> AppContent? { profileFirestoreService.loadAppContent(id: id) }
    /// Saves the full UserProfile to Firestore.
    /// Guarded by isProfileLoaded — never saves the blank placeholder
    /// profile that exists before loadProfileFromFirestore() completes.
    /// This is the fix for BUG-016 (midnight race wipes user data).
    func saveProfileToFirestore() {
        guard isProfileLoaded, let userId = currentUserId else { return }
        profileFirestoreService.saveProfileToFirestore(userId: userId, profile: userProfile)
    }

    /// Saves ONLY the three pregnancy-progress fields computed by the
    /// midnight refresh (week, gestationalDay, trimester) using Firestore
    /// updateData so no other field is touched. Safe to call even before
    /// the full profile has been loaded from Firestore.
    func savePregnancyProgressFieldsToFirestore(week: Int, gestationalDay: Int, trimester: Trimester) {
        guard let userId = currentUserId else { return }
        db.collection("users").document(userId).updateData([
            "userDetails.week": week,
            "userDetails.gestationalDay": gestationalDay,
            "userDetails.trimester": trimester.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func createUserDocumentIfNeeded(completion: @escaping () -> Void) {
        guard let userId = currentUserId else {
            completion()
            return
        }
        profileFirestoreService.createUserDocumentIfNeeded(userId: userId, profile: userProfile, completion: completion)
    }

    func markOnboardingCompleted() {
        guard let userId = currentUserId else { return }
        profileFirestoreService.markOnboardingCompleted(userId: userId)
    }

    func loadProfileFromFirestore(completion: @escaping (UserProfile?) -> Void) {
        guard let userId = currentUserId else { completion(nil); return }
        profileFirestoreService.loadProfileFromFirestore(userId: userId) { profile in
            guard let profile else { completion(nil); return }
            self.userProfile = profile
            // Mark the profile as loaded BEFORE calling refreshPregnancyProgressIfNeeded
            // so the subsequent saveProfileToFirestore() inside that call is allowed.
            self.isProfileLoaded = true
            self.refreshPregnancyProgressIfNeeded()
            self.refreshProgressIndexesAfterProfileUpdate()
            completion(self.userProfile)
        }
    }
}

extension DataController {
    func saveUserFeedback(activityId: String, difficulty: DifficultyLevel, fatigue: FatigueLevel, note: String?) {
        feedbackService.saveUserFeedback(activityId: activityId, difficulty: difficulty, fatigue: fatigue, note: note)
    }
    func hasFeedback(for activityId: String) -> Bool { feedbackService.hasFeedback(for: activityId) }
    func shouldPromptForFeedback(for activityId: String, on date: Date) -> Bool {
        feedbackService.shouldPromptForFeedback(for: activityId, on: date)
    }
}

extension DataController {
    func insightHealthItemsForCurrentWeek() -> [HealthItem] { insightsViewModel.insightHealthItemsForCurrentWeek() }
    func insightHealthItems(for gestationalWeek: Int) -> [HealthItem] {
        insightsViewModel.insightHealthItems(for: gestationalWeek)
    }
    func loadInsightsResponse() -> InsightsResponse? { insightsViewModel.loadInsightsResponse() }
    func activityWeekProgressSnapshot(for activity: ActivityType, gestationalWeek: Int) -> ActivityWeekProgressSnapshot? {
        insightsViewModel.activityWeekProgressSnapshot(for: activity, gestationalWeek: gestationalWeek)
    }
    func enrichedInsightSession(from session: InsightSession?, activityType: String, dateText: String) -> InsightSession? {
        insightsViewModel.enrichedInsightSession(from: session, activityType: activityType, dateText: dateText)
    }
    func feedbackForInsightSession(sessionId: String?, activityType: String, dateText: String) -> UserFeedback? {
        insightsViewModel.feedbackForInsightSession(sessionId: sessionId, activityType: activityType, dateText: dateText)
    }
    func latestGestationalWeekWithProgress(for activity: ActivityType) -> Int? {
        insightsViewModel.latestGestationalWeekWithProgress(for: activity)
    }
    func preferredInsightWeek(for activity: ActivityType, preferredWeek: Int) -> Int {
        insightsViewModel.preferredInsightWeek(for: activity, preferredWeek: preferredWeek)
    }
    func loadInsightsFromJSON() -> [InsightResponse] { insightsViewModel.loadInsightsFromJSON() }
    func getCategoriesForCurrentWeek() -> [Category] { insightsViewModel.getCategoriesForCurrentWeek() }
    func getInsightCardsForCurrentWeek() -> [Insights] { insightsViewModel.getInsightCardsForCurrentWeek() }
    func getCategoryById(_ id: String) -> Category? { insightsViewModel.getCategoryById(id) }
    func getDetailForCategory(id: String) -> (title: String, body: String)? {
        insightsViewModel.getDetailForCategory(id: id)
    }
    func loadInsightDetail(section: String, week: Int) -> InsightDetail? {
        insightsViewModel.loadInsightDetail(section: section, week: week)
    }
}

extension DataController {
    func changePassword(old: String, new: String, confirm: String) -> (Bool, String) {
        profileViewModel.changePassword(old: old, new: new, confirm: confirm)
    }
    func updateUserName(name: String) { profileViewModel.updateUserName(name: name) }
    func updateUserCredentials(username: String, password: String) {
        profileViewModel.updateUserCredentials(username: username, password: password)
    }
    func updateUserAge(_ age: Int) { profileViewModel.updateUserAge(age) }
    func updateGestationalWeek(_ week: Int, _ currentTrimester: Trimester) {
        profileViewModel.updateGestationalWeek(week, currentTrimester)
    }
    func updatePregnancyDates(lmpDate: Date, eddDate: Date, gestationalWeek: Int, gestationalDay: Int, trimester: Trimester) {
        profileViewModel.updatePregnancyDates(
            lmpDate: lmpDate,
            eddDate: eddDate,
            gestationalWeek: gestationalWeek,
            gestationalDay: gestationalDay,
            trimester: trimester
        )
    }
    func updateMedicalCondition(_ condition: [MedicalCondition]) {
        profileViewModel.updateMedicalCondition(condition)
    }
    func updateActivityLevel(_ level: ActivityLevel) { profileViewModel.updateActivityLevel(level) }
    func updateActivityLevelFromProgressIfNeeded(referenceDate: Date = Date()) {
        profileViewModel.updateActivityLevelFromProgressIfNeeded(referenceDate: referenceDate)
    }
    func updateHasAppleWatch(_ watchStatus: Bool) { profileViewModel.updateHasAppleWatch(watchStatus) }
    func updateProfileImage(_ image: UIImage) {
        guard let userId = currentUserId else { return }
        profileViewModel.updateProfileImage(image, userId: userId)
    }
    var onboardingGreetings: [String] { profileViewModel.onboardingGreetings }
    func onboardingGreeting(at index: Int) -> String { profileViewModel.onboardingGreeting(at: index) }
}

extension DataController {
    func checkUserExists(username: String, completion: @escaping (Bool, [String: Any]?) -> Void) {
        authViewModel.checkUserExists(username: username, completion: completion)
    }
    func loginWithUsername(credentials: LoginCredentials, completion: @escaping (Result<UserProfile, LoginError>, AuthState) -> Void) {
        authViewModel.loginWithUsername(credentials: credentials, completion: completion)
    }
    func signInWithGoogle(from viewController: UIViewController, completion: @escaping (Result<UserProfile, Error>, AuthState) -> Void) {
        authViewModel.signInWithGoogle(from: viewController, completion: completion)
    }
    func signInAsGuest() -> UserProfile { authViewModel.signInAsGuest() }
    func logout() { authViewModel.logout() }
}

extension DataController {
    func dynamicFootnote(routineType: RoutineType, completedItems: Int, totalItems: Int, rotationSeed: Int) -> [String] {
        homeViewModel.dynamicFootnote(routineType: routineType, completedItems: completedItems, totalItems: totalItems, rotationSeed: rotationSeed)
    }
    func progressBucket(completed: Int, total: Int) -> ProgressBucket {
        homeViewModel.progressBucket(completed: completed, total: total)
    }
    func getWatchVitals() -> [WatchVitalViewModel] { homeViewModel.getWatchVitals() }
    func getGreetingMessage() -> String { homeViewModel.getGreetingMessage() }
    func getVitalsSubtitle() -> String { homeViewModel.getVitalsSubtitle() }
    func getDayItems() -> [DayItem] { homeViewModel.getDayItems() }
    func homeWeeklyProgressSnapshot() -> HomeWeeklyProgressSnapshot { homeViewModel.homeWeeklyProgressSnapshot() }
    func saveRegistrationDate() { homeViewModel.saveRegistrationDate() }
    func getRegistrationDate() -> Date { homeViewModel.getRegistrationDate() }
    func getWeekDayLabels() -> [String] { homeViewModel.getWeekDayLabels() }
    func getWeekDayKeys() -> [String] { homeViewModel.getWeekDayKeys() }
    func getChartValues(for routineType: RoutineType) -> [Double] {
        homeViewModel.getChartValues(for: routineType)
    }
    func getCurrentStreak() -> Int { homeViewModel.getCurrentStreak() }
    func getLongestStreak() -> Int { homeViewModel.getLongestStreak() }
    func getOverallCompletionPercent(for date: Date) -> Int {
        homeViewModel.getOverallCompletionPercent(for: date)
    }
    func getMotivationMessage() -> String { homeViewModel.getMotivationMessage() }
    func setupGuestRegistrationDate() { homeViewModel.setupGuestRegistrationDate() }
    func getMostRecentlyActiveItem(for type: RoutineType, date: Date) -> (item: RoutineItem, progress: RoutineItemProgress)? {
        routineViewModel.getMostRecentlyActiveItem(for: type, date: date)
    }
}

#if DEBUG
extension DataController {
    func loadDummyProgressDataUntilCurrentDay(completion: (() -> Void)? = nil) {
        debugSeedService.loadDummyProgressDataUntilCurrentDay(completion: completion)
    }
}
#endif

extension DataController: RoutineEngineContext {
    var userFeedback: [UserFeedback] { progressStoreService.userFeedback }
    func snapshot(forDayKey key: String) -> RoutineDaySnapshot? {
        routineSnapshotService.snapshot(for: key, userId: currentUserId)
    }
    func routineType(for activityId: String) -> RoutineType {
        insightsViewModel.routineType(for: activityId)
    }
}

extension DataController: InsightsDataSourceProtocol {
    func weekRecords(for gestationalWeek: Int) -> [String: [String: ActivityExecutionRecord]] {
        progressStoreService.weekRecords(for: gestationalWeek)
    }
}

extension DataController: HomeDataSourceProtocol {}
