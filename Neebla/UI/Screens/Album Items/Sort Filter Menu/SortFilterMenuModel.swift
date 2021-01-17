//
//  SortFilterMenuModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/17/21.
//

import Foundation
import iOSShared
import SFSafeSymbols
import SQLite

class SortFilterMenuModel: ObservableObject {
    var sortFilterModel: SortFilterSettings?
    @Published var sortOrderChevron: SFSymbol = .chevronUp
    @Published var showAllIcon: SFSymbol = .rectangle
    @Published var showOnlyUnreadIcon: SFSymbol = .rectangle
    
    init() {
        do {
            sortFilterModel = try SortFilterSettings.getSingleton(db: Services.session.db)
            setSortOrder()
            setFilterIcons()
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func toggleSortOrder() {
        guard let model = sortFilterModel else {
            return
        }

        let update = !model.sortByOrderAscending
        do {
            self.sortFilterModel = try model.update(setters: SortFilterSettings.sortByOrderAscendingField.description <- update)
            setSortOrder()
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func select(filter: SortFilterSettings.DiscussionFilterBy) {
        guard let model = sortFilterModel else {
            return
        }
        
        do {
            self.sortFilterModel = try model.update(setters: SortFilterSettings.discussionFilterByField.description <- filter)
            setFilterIcons()
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    private func setSortOrder() {
        guard let model = sortFilterModel else {
            return
        }
        
        sortOrderChevron = model.sortByOrderAscending ? .chevronUp : .chevronDown
    }
    
    private func setFilterIcons() {
        guard let model = sortFilterModel else {
            return
        }
        
        func getIcon(filter: SortFilterSettings.DiscussionFilterBy) -> SFSymbol {
            if model.discussionFilterBy == filter {
                return .checkmarkRectangle
            }
            else {
                return .rectangle
            }
        }
        
        for filterBy in SortFilterSettings.DiscussionFilterBy.allCases {
            switch filterBy {
            case .none:
                showAllIcon = getIcon(filter: filterBy)
                
            case .onlyUnread:
                showOnlyUnreadIcon = getIcon(filter: filterBy)
            }
        }
    }
}
