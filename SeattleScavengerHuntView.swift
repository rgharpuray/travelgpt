import SwiftUI

struct SeattleScavengerHuntView: View {
    @StateObject private var progress = ScavengerHuntProgressManager()
    @State private var selectedCategory: SeattleScavengerHunt.ScavengerHuntCategory? = nil
    @State private var showingActivityDetail = false
    @State private var selectedActivity: SeattleScavengerHunt.ScavengerHuntActivity? = nil
    @State private var showingAchievements = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Progress Overview
                    progressOverview
                    
                    // MARK: - Category Filter
                    categoryFilter
                    
                    // MARK: - Activities List
                    activitiesList
                    
                }
                .padding()
            }
            .navigationTitle("Seattle Scavenger Hunt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Achievements") {
                        showingAchievements = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingActivityDetail) {
            if let activity = selectedActivity {
                ActivityDetailView(activity: activity, progress: progress)
            }
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(progress: progress)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Seattle Scavenger Hunt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("24 Amazing Activities Across the City")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Completed",
                    value: "\(progress.progress.completedActivities.count)",
                    total: "24",
                    color: .green
                )
                
                StatCard(
                    title: "Points",
                    value: "\(progress.progress.totalPoints)",
                    total: "1,200",
                    color: .blue
                )
                
                StatCard(
                    title: "Categories",
                    value: "\(progress.progress.categoriesCompleted.count)",
                    total: "10",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Overview
    
    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(progress.progress.completionPercentage))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress.progress.completionPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("Current Streak: \(progress.progress.currentStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Best Streak: \(progress.progress.longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        count: SeattleScavengerHunt.seattleActivities.count
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(SeattleScavengerHunt.ScavengerHuntCategory.allCases, id: \.self) { category in
                        let activities = SeattleScavengerHunt.getActivitiesByCategory(category)
                        let completedCount = activities.filter { progress.progress.completedActivities.contains($0.id) }.count
                        
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: activities.count,
                            completedCount: completedCount
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Activities List
    
    private var activitiesList: some View {
        LazyVStack(spacing: 12) {
            let filteredActivities = selectedCategory == nil ? 
                SeattleScavengerHunt.seattleActivities : 
                SeattleScavengerHunt.getActivitiesByCategory(selectedCategory!)
            
            ForEach(filteredActivities) { activity in
                ActivityCard(
                    activity: activity,
                    isCompleted: progress.progress.completedActivities.contains(activity.id)
                ) {
                    selectedActivity = activity
                    showingActivityDetail = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let total: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("/ \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct CategoryChip: View {
    let category: SeattleScavengerHunt.ScavengerHuntCategory?
    let isSelected: Bool
    let count: Int
    let completedCount: Int?
    let action: () -> Void
    
    init(category: SeattleScavengerHunt.ScavengerHuntCategory?, isSelected: Bool, count: Int, completedCount: Int? = nil, action: @escaping () -> Void) {
        self.category = category
        self.isSelected = isSelected
        self.count = count
        self.completedCount = completedCount
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                } else {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                }
                
                Text(category?.displayName ?? "All")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? (category?.color ?? .blue) : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityCard: View {
    let activity: SeattleScavengerHunt.ScavengerHuntActivity
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category Icon
                VStack {
                    Image(systemName: activity.category.icon)
                        .font(.title2)
                        .foregroundColor(activity.category.color)
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .frame(width: 40)
                
                // Activity Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(activity.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("\(activity.points)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(activity.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        DifficultyBadge(difficulty: activity.difficulty)
                        
                        Spacer()
                        
                        Text(activity.timeEstimate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyBadge: View {
    let difficulty: SeattleScavengerHunt.ScavengerHuntActivity.Difficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(difficulty.color.opacity(0.2))
            .foregroundColor(difficulty.color)
            .cornerRadius(4)
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: SeattleScavengerHunt.ScavengerHuntActivity
    @ObservedObject var progress: ScavengerHuntProgressManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPhotoChallenge = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: activity.category.icon)
                                .font(.title)
                                .foregroundColor(activity.category.color)
                            
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(activity.category.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(activity.description)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Challenge Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Challenge")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(activity.challenge)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Photo Challenge")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(activity.photoChallenge)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "star.fill", title: "Points", value: "\(activity.points)")
                        DetailRow(icon: "clock.fill", title: "Time", value: activity.timeEstimate)
                        DetailRow(icon: "location.fill", title: "Location", value: activity.location)
                        DetailRow(icon: "exclamationmark.triangle.fill", title: "Difficulty", value: activity.difficulty.displayName)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(activity.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.top, 2)
                                
                                Text(tip)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Action Button
                    Button(action: {
                        if progress.progress.completedActivities.contains(activity.id) {
                            // Already completed
                        } else {
                            progress.markActivityCompleted(activity.id)
                        }
                    }) {
                        HStack {
                            Image(systemName: progress.progress.completedActivities.contains(activity.id) ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                            
                            Text(progress.progress.completedActivities.contains(activity.id) ? "Completed!" : "Mark as Complete")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(progress.progress.completedActivities.contains(activity.id) ? Color.green : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(progress.progress.completedActivities.contains(activity.id))
                }
                .padding()
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @ObservedObject var progress: ScavengerHuntProgressManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(SeattleScavengerHunt.ScavengerHuntAchievement.allCases, id: \.self) { achievement in
                        AchievementCard(achievement: achievement, progress: progress)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: SeattleScavengerHunt.ScavengerHuntAchievement
    @ObservedObject var progress: ScavengerHuntProgressManager
    
    private var isUnlocked: Bool {
        switch achievement {
        case .firstActivity:
            return progress.progress.completedActivities.count >= 1
        case .categoryExplorer:
            return progress.progress.categoriesCompleted.count >= 5
        case .pointCollector:
            return progress.progress.totalPoints >= 500
        case .photoMaster:
            return progress.progress.completedActivities.count >= 10
        case .seattleExpert:
            return progress.progress.completedActivities.count >= 15
        case .completionist:
            return progress.progress.completedActivities.count >= 24
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isUnlocked ? Color.yellow.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Progress Manager

class ScavengerHuntProgressManager: ObservableObject {
    @Published var progress = SeattleScavengerHunt.ScavengerHuntProgress()
    
    private let progressKey = "seattleScavengerHuntProgress"
    
    init() {
        loadProgress()
    }
    
    func markActivityCompleted(_ activityId: Int) {
        if !progress.completedActivities.contains(activityId) {
            progress.completedActivities.insert(activityId)
            
            // Update points
            if let activity = SeattleScavengerHunt.seattleActivities.first(where: { $0.id == activityId }) {
                progress.totalPoints += activity.points
                
                // Update categories completed
                progress.categoriesCompleted.insert(activity.category)
            }
            
            // Update streak
            let today = Calendar.current.startOfDay(for: Date())
            if let lastActivity = progress.lastActivityDate {
                let lastActivityDay = Calendar.current.startOfDay(for: lastActivity)
                if today.timeIntervalSince(lastActivityDay) == 86400 { // 1 day
                    progress.currentStreak += 1
                } else if today.timeIntervalSince(lastActivityDay) > 86400 {
                    progress.currentStreak = 1
                }
            } else {
                progress.currentStreak = 1
            }
            
            progress.longestStreak = max(progress.longestStreak, progress.currentStreak)
            progress.lastActivityDate = Date()
            
            saveProgress()
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(SeattleScavengerHunt.ScavengerHuntProgress.self, from: data) {
            progress = decoded
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
}

// MARK: - Preview

struct SeattleScavengerHuntView_Previews: PreviewProvider {
    static var previews: some View {
        SeattleScavengerHuntView()
    }
}


