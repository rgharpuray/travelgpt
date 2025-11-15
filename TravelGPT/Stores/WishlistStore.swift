import Foundation
import SwiftUI

@MainActor
class WishlistStore: ObservableObject {
    @Published var wishlistEntries: [WishlistEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = WishlistAPIService.shared
    
    // Callback to notify other stores about wishlist changes
    var onWishlistChange: ((Int, Bool, WishlistPriority?) -> Void)?
    
    // MARK: - Public Methods
    
    func refreshWishlist() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let entries = try await apiService.getWishlist()
            wishlistEntries = entries
            print("✅ Wishlist refreshed with \(entries.count) entries")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error refreshing wishlist: \(error)")
        }
        
        isLoading = false
    }
    
    func getWishlistByPriority(_ priority: WishlistPriority) -> [WishlistEntry] {
        return wishlistEntries.filter { $0.priority == priority }
    }
    
    func addToWishlist(cardId: Int, priority: WishlistPriority, notes: String? = nil) async -> Bool {
        do {
            let newEntry = try await apiService.addToWishlist(cardId: cardId, priority: priority, notes: notes)
            
            // Update local state
            if let existingIndex = wishlistEntries.firstIndex(where: { $0.card.id == cardId }) {
                wishlistEntries[existingIndex] = newEntry
            } else {
                wishlistEntries.append(newEntry)
            }
            
            // Sort by priority
            sortWishlist()
            
            // Notify about the change
            onWishlistChange?(cardId, true, priority)
            
            print("✅ Added card \(cardId) to wishlist with priority \(priority.rawValue)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error adding to wishlist: \(error)")
            return false
        }
    }
    
    func updateWishlistEntry(wishlistId: Int, priority: WishlistPriority? = nil, notes: String? = nil) async -> Bool {
        do {
            let updateResponse = try await apiService.updateWishlistEntry(wishlistId: wishlistId, priority: priority, notes: notes)
            
            // Update local state by finding the entry and updating its fields
            if let index = wishlistEntries.firstIndex(where: { $0.id == wishlistId }) {
                var updatedEntry = wishlistEntries[index]
                // Create a new entry with updated fields
                let newEntry = WishlistEntry(
                    id: updatedEntry.id,
                    card: updatedEntry.card,
                    user: updatedEntry.user,
                    device_id: updatedEntry.device_id,
                    priority: updateResponse.priority,
                    notes: updateResponse.notes,
                    created_at: updatedEntry.created_at,
                    updated_at: updatedEntry.updated_at
                )
                wishlistEntries[index] = newEntry
                sortWishlist()
                
                // Notify about the change
                onWishlistChange?(newEntry.card.id, true, updateResponse.priority)
            }
            
            print("✅ Updated wishlist entry \(wishlistId)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error updating wishlist entry: \(error)")
            return false
        }
    }
    
    func removeFromWishlist(cardId: Int) async -> Bool {
        do {
            try await apiService.removeFromWishlist(cardId: cardId)
            
            // Update local state
            wishlistEntries.removeAll { $0.card.id == cardId }
            
            // Notify about the change
            onWishlistChange?(cardId, false, nil)
            
            print("✅ Removed card \(cardId) from wishlist")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error removing from wishlist: \(error)")
            return false
        }
    }
    
    func deleteWishlistEntry(wishlistId: Int) async -> Bool {
        do {
            try await apiService.deleteWishlistEntry(wishlistId: wishlistId)
            
            // Update local state
            wishlistEntries.removeAll { $0.id == wishlistId }
            
            print("✅ Deleted wishlist entry \(wishlistId)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error deleting wishlist entry: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    func isCardInWishlist(cardId: Int) -> Bool {
        return wishlistEntries.contains { $0.card.id == cardId }
    }
    
    func getWishlistPriority(for cardId: Int) -> WishlistPriority? {
        return wishlistEntries.first { $0.card.id == cardId }?.priority
    }
    
    func getWishlistEntry(for cardId: Int) -> WishlistEntry? {
        return wishlistEntries.first { $0.card.id == cardId }
    }
    
    private func sortWishlist() {
        wishlistEntries.sort { entry1, entry2 in
            let priorityOrder: [WishlistPriority] = [.mustDo, .soundsFun, .maybe]
            let index1 = priorityOrder.firstIndex(of: entry1.priority) ?? 999
            let index2 = priorityOrder.firstIndex(of: entry2.priority) ?? 999
            
            if index1 != index2 {
                return index1 < index2
            }
            
            // If same priority, sort by creation date (newest first)
            return entry1.created_at > entry2.created_at
        }
    }
    
    // MARK: - Statistics
    
    var totalCount: Int {
        return wishlistEntries.count
    }
    
    var mustDoCount: Int {
        return wishlistEntries.filter { $0.priority == .mustDo }.count
    }
    
    var soundsFunCount: Int {
        return wishlistEntries.filter { $0.priority == .soundsFun }.count
    }
    
    var maybeCount: Int {
        return wishlistEntries.filter { $0.priority == .maybe }.count
    }
}

