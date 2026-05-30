//
//  Extension.swift
//  prenatalPregnancy
//
//  Created by GEU on 30/03/26.
//

import UIKit

extension RoutineType {
    
    var displayTitle: String {
        switch self {
        case .walking: return "Walking"
        case .exercise: return "Exercise"
        case .yoga: return "Yoga"
        }
    }
    
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .exercise: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        }
    }
    
    func footnotes(for routineType: RoutineType, bucket: ProgressBucket) -> [String] {
        switch self {
        case .walking:
            switch bucket {
            case .notStarted:
                return [
                    "A short walk can boost your energy 🌱", "Gentle movement helps circulation", "Start slow, your body will thank you",
                    "Fresh air is a natural mood lifter", "A 5-minute start is better than no start", "Clear your head with a few steps",
                    "Walking lowers cortisol and stress", "Your joints thrive on low-impact movement", "Step outside to reset your perspective",
                    "Small steps lead to big changes", "Wake up your metabolic rate", "Ideal for clearing a mental block",
                    "Lace up; your heart deserves the love", "Movement is medicine for the mind", "Find your pace, find your peace",
                    "The hardest step is the one out the door", "Boost your vitamin D and your mood", "Simple movement, profound benefits",
                    "Your body was built to move", "Energize your afternoon with a stroll"
                ]
            case .started:
                return [
                    "Nice start! Keep your pace comfortable", "Every step supports healthy blood flow", "Find a rhythm that feels natural",
                    "Swing your arms gently to engage more", "Notice the world around you", "You're already ahead of the couch",
                    "Breathe deeply as you find your stride", "Feel the tension leaving your shoulders", "Your muscles are warming up nicely",
                    "Hydrate if you're feeling the heat", "Maintain a steady, purposeful gait", "You’re doing something great for your heart",
                    "Focus on the sensation of your feet landing", "The blood is pumping, keep it going", "Enjoy the rhythm of your own movement",
                    "A natural pace is the best pace", "Stay upright and look at the horizon", "Building momentum, one step at a time",
                    "You’ve successfully shifted into gear", "The journey is just as good as the finish"
                ]
            case .midway:
                return [
                    "Great going! You're halfway there 👏", "Walking builds stamina and balance", "You’re oxygenating your brain right now",
                    "Consistency is where the magic happens", "Halfway done; heart is reaping rewards", "Endurance is built in the middle miles",
                    "Your cardiovascular system is working hard", "Keep that chin up and chest open", "Notice how your energy has shifted",
                    "The halfway mark is a sign of strength", "You've found your flow, stay with it", "Walking is the ultimate longevity tool",
                    "Your brain is releasing happy chemicals now", "Midway point—take a deep, full breath", "Your legs feel stronger with every minute",
                    "Keep the momentum; you’re doing great", "Halfway through your daily health investment", "Balance and coordination are improving",
                    "Stay present in the movement", "Crushing those goals, one block at a time"
                ]
            case .almostDone:
                return [
                    "Almost done! Stay relaxed", "Finish strong, you're doing great 💚", "The home stretch! Keep posture tall",
                    "Nearly there—deep breaths to finish", "Your future self is thanking you", "The finish line is just around the corner",
                    "Maintain your form until the very end", "Don't slow down just yet, stay steady", "Feel the accomplishment building up",
                    "A few more minutes of pure focus", "You've proven your discipline today", "Your circulation is at its peak",
                    "Last stretch—keep your stride light", "Almost home, keep the energy high", "Finish with the same intent you started",
                    "The final minutes are for your mindset", "You’re nearly at your daily goal", "One last push for your well-being",
                    "The hardest work is behind you now", "Closing in on a successful session"
                ]
            case .completed:
                return [
                    "Excellent work! Walking complete 🎉", "You've supported your heart and joints", "Vitality looks good on you",
                    "Take a moment to enjoy the calm", "Step count boosted! Great job", "You’ve lowered your stress levels today",
                    "Cool down and let your heart rate settle", "Consistency is the key to health", "Your body feels more alive now",
                    "A perfect end to a healthy habit", "You’ve cleared your mind and body", "Reflect on how much better you feel",
                    "You’ve clocked in the miles and the effort", "Walk complete—time to recover", "Your metabolism is humming now",
                    "Another win for your long-term health", "Rest easy knowing you moved today", "Great discipline shown today",
                    "Your heart is stronger than it was before", "Victory! You finished what you started"
                ]
            }
            
        case .exercise:
            switch bucket {
            case .notStarted:
                return [
                    "Strength begins with the first move", "Gentle exercises build daily comfort", "Wake up those muscles; they’re ready",
                    "Small efforts lead to big changes", "Focus on the feeling after the workout", "Your future strength starts right here",
                    "Prepare your space and your mind", "Today's effort is tomorrow's ease", "Building a stronger you, one rep at a time",
                    "Commit to the first five minutes", "Discipline is doing what needs to be done", "Unlock your physical potential",
                    "Action is the antidote to lethargy", "Your muscles are waiting for the signal", "Movement creates motivation",
                    "Invest in your physical longevity", "Strength training protects your bones", "Get ready to feel powerful",
                    "Transform your energy through effort", "You are capable of more than you think"
                ]
            case .started:
                return [
                    "Nice start! Focus on form", "Controlled movement builds strength", "Quality over quantity—make it count",
                    "Engage your core for better stability", "Feel the energy starting to shift", "Warm muscles are efficient muscles",
                    "Mind-muscle connection is key", "Exhale on the exertion", "Setting the tone with solid reps",
                    "Your body is adapting to the challenge", "Keep your movements smooth and steady", "Building the foundation for power",
                    "Stay concentrated on the muscle group", "Don't rush the tempo, feel the work", "Initial resistance is where growth begins",
                    "Great start—keep that focus sharp", "Every rep is a brick in the wall", "Listen to your body as you ramp up",
                    "Your pulse is rising, keep it going", "Activation complete; let's get to work"
                ]
            case .midway:
                return [
                    "You're building strength steadily 💪", "Muscle support improves posture", "Pushing through the middle builds grit",
                    "Your bones get stronger with challenge", "You’re past the hardest part: starting", "Intensity is where the change happens",
                    "The middle is where progress is made", "Stay hydrated and keep your form", "You are stronger than your excuses",
                    "Focus on your breathing during the peak", "Muscular endurance is growing right now", "Midway through—don't let up",
                    "Embrace the burn; it’s a sign of work", "Your metabolism is firing on all cylinders", "Stay disciplined, stay focused",
                    "This is the heart of the workout", "You’re rewriting your physical limits", "Challenge yourself to stay steady",
                    "Keep that posture tight and aligned", "Halfway to a brand new you"
                ]
            case .almostDone:
                return [
                    "Almost there! Stay mindful", "Strong finish means better recovery", "Final push—give it full attention",
                    "Muscle fatigue is a sign of growth", "The finish line is in sight!", "Last few reps for maximum impact",
                    "Finish as strong as you started", "Don't compromise on form at the end", "You’ve nearly reached your goal",
                    "Dig deep for the final set", "The end of the session is the most rewarding", "Maintain control until the final second",
                    "Your body is tired, but your mind is tough", "Success is just a few moves away", "Finish with pride and precision",
                    "Last bit of effort before the cooldown", "You've put in the work, now finish it", "Stay focused on the very last rep",
                    "The home stretch of your strength build", "Almost time to celebrate the work"
                ]
            case .completed:
                return [
                    "Workout complete! Well done 🎉", "Strength today means comfort tomorrow", "Powerhouse move! You crushed that",
                    "Your body is now in recovery mode", "Discipline looks great on you", "Rest and refuel—you earned it",
                    "Your muscles will grow stronger tonight", "Celebrate the effort you put in", "Another session in the books",
                    "You’ve improved your functional strength", "Feel the post-workout endorphins", "A stronger heart and a stronger body",
                    "The work is done; time to relax", "You showed up and you leveled up", "Consistency wins every single time",
                    "Your metabolism will stay elevated", "Take pride in your physical progress", "Recovery is just as important as the work",
                    "Excellent session, mission accomplished", "You’re one step closer to your peak"
                ]
            }
            
        case .yoga:
            switch bucket {
            case .notStarted:
                return [
                    "Begin with calm breathing 🧘‍♀️", "Yoga helps body and mind connect", "Quiet the noise and step on the mat",
                    "Honor where your body is today", "Flexibility starts in the mind", "Find a quiet space for your soul",
                    "Prepare to release built-up tension", "Set an intention for your practice", "Your mat is a place of no judgment",
                    "Slow down to speed up your recovery", "Connect with your inner stillness", "Yoga is a gift you give yourself",
                    "Prepare your breath for the flow", "Open your heart and your mind", "Leave the day's stress at the edge of the mat",
                    "A peaceful mind leads to a peaceful body", "Find your center before you move", "Ready to flow with grace and ease",
                    "Your practice is unique to you", "Softness is a form of strength"
                ]
            case .started:
                return [
                    "Nice flow, keep breathing steadily", "Gentle stretches ease tension", "Let your breath lead the movement",
                    "Release tension in your jaw", "Every inhale is new energy", "Feel the length in your spine",
                    "Root down to rise up", "Notice the air entering your lungs", "Moving with purpose and presence",
                    "Gently waking up the connective tissue", "Your breath is your anchor", "Soften your gaze and find focus",
                    "Transition with care and awareness", "Creating space where there was tightness", "Let the movement feel natural",
                    "Find the balance between effort and ease", "Expanding with every conscious breath", "The start of a beautiful flow",
                    "Listen to the wisdom of your body", "Ease into the rhythm of the practice"
                ]
            case .midway:
                return [
                    "You're finding balance and calm", "Flexibility supports posture changes", "Balance is a practice, not a destination",
                    "Creating space in your spine and spirit", "Flow with intention and grace", "Stay centered in the present moment",
                    "Inhale peace, exhale resistance", "Your body is becoming more fluid", "Deepen your focus on the inner self",
                    "Strength and flexibility in harmony", "Midway through your journey inward", "Notice the heat you’ve cultivated",
                    "Stay with the breath through the challenge", "Allow your mind to be as flexible as your body", "Finding stillness within the motion",
                    "Your alignment is improving with every pose", "The middle of the flow is pure presence", "Cultivate patience in every stretch",
                    "Release the need for perfection", "You are exactly where you need to be"
                ]
            case .almostDone:
                return [
                    "Almost complete, stay present", "Slow movements bring relaxation", "Deepen presence for final moments",
                    "Transition slowly; there's no rush", "Peace is found in the final stretches", "Prepare for total relaxation",
                    "The hardest work of the mind is done", "Settle into the deeper stretches now", "A few more breaths of pure calm",
                    "Feel the gratitude for your body", "The calm within you is growing", "Almost time for complete stillness",
                    "Let the final poses ground you", "Your nervous system is calming down", "Closing the practice with intention",
                    "Relax into the final moments of effort", "Nearly ready for your final rest", "Every cell is benefiting from this flow",
                    "Slow down the breath even further", "The transition to stillness has begun"
                ]
            case .completed:
                return [
                    "Yoga complete! Feel the calm ✨", "You've supported flexibility and peace", "Namaste. You’ve nourished your soul",
                    "Carry this stillness into your day", "You are more aligned now", "The peace you feel is yours to keep",
                    "Your body is open and your mind is clear", "Practice finished; spirit renewed", "You’ve balanced your energy today",
                    "Take this mindfulness off the mat", "You’ve created space for joy", "A beautiful session for mind and body",
                    "Your nervous system is reset", "Honor the effort you gave today", "Feel the lightness in your limbs",
                    "You are grounded, centered, and whole", "Reflect on the calm you've created", "The benefits will stay with you all day",
                    "Yoga complete—well done for showing up", "Peace starts within. Great practice."
                ]
            }
        }
    }
}

extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
