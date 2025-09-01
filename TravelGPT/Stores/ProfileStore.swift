import Foundation
import Combine

@MainActor
class ProfileStore: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var error: String?
    
    private let profileKey = "cachedProfile"
    
    init() {
        print("👤 ProfileStore initialized")
        loadCachedProfile()
        
        // Don't automatically fetch profile on init - let the app initialization handle it
        // This prevents race conditions and ensures proper initialization order
    }
    
    func fetchProfile() async {
        print("👤 Fetching profile...")
        isLoading = true
        error = nil
        
        do {
            let profile = try await BackendService.shared.fetchProfile()
            print("✅ Profile fetched successfully: \(profile)")
            self.profile = profile
            cacheProfile(profile)
        } catch {
            print("❌ Failed to fetch profile: \(error)")
            
            // Load cached profile if available
            if self.profile == nil {
                loadCachedProfile()
            }
            
            // Only show error if we don't have any profile data at all
            if self.profile == nil {
                self.error = "Failed to load profile: \(error.localizedDescription)"
            } else {
                print("ℹ️ Using cached profile despite fetch failure")
                // Don't show error if we have cached data
            }
        }
        
        isLoading = false
    }
    
    func updateProfile(petName: String?) async {
        print("Updating profile with pet name: \(petName ?? "nil")") // Debug print
        isLoading = true
        error = nil
        do {
            let profile = try await BackendService.shared.updateProfile(petName: petName)
            print("Profile updated successfully: \(profile)") // Debug print
            self.profile = profile
            cacheProfile(profile)
        } catch {
            print("Failed to update profile: \(error)") // Debug print
            self.error = "Failed to update profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func uploadProfileImage(imageData: Data, fileName: String) async {
        print("Uploading profile image: \(fileName)")
        isLoading = true
        error = nil
        
        do {
            let imageUrl = try await BackendService.shared.uploadProfileImage(imageData: imageData, fileName: fileName)
            print("✅ Profile image uploaded successfully: \(imageUrl)")
            
            // Update the current profile with the new image URL
            if var currentProfile = self.profile {
                currentProfile.profile_image_url = imageUrl
                self.profile = currentProfile
                cacheProfile(currentProfile)
            } else {
                // If no profile exists, we'll need to fetch a fresh profile
                // since we can't create one with the current model structure
                print("ℹ️ No existing profile, fetching fresh profile after image upload")
                await fetchProfile()
            }
        } catch {
            print("❌ Failed to upload profile image: \(error)")
            self.error = "Failed to upload image: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Caching
    
    private func cacheProfile(_ profile: Profile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: profileKey)
            print("💾 Profile cached successfully")
        } catch {
            print("❌ Failed to cache profile: \(error)")
        }
    }
    
    private func loadCachedProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            print("ℹ️ No cached profile found")
            return
        }
        
        do {
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            self.profile = profile
            print("✅ Loaded cached profile: \(profile)")
        } catch {
            print("❌ Failed to decode cached profile: \(error)")
            // Clear invalid cached data
            UserDefaults.standard.removeObject(forKey: profileKey)
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        print("🗑️ Profile cache cleared")
    }
} 