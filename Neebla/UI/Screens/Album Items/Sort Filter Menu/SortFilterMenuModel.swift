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
    let sortFilterModel: SortFilterSettings?
    @Published var sortOrderChevron: SFSymbol = .chevronUp
    @Published var showAllIcon: SFSymbol = .rectangle
    @Published var showOnlyUnreadIcon: SFSymbol = .rectangle
    @Published var filtersEnabled: Bool = true
    
    init(sortFilterModel: SortFilterSettings?) {
        self.sortFilterModel = sortFilterModel
        setSortOrder()
        setFilterIcons()
        updateFiltersEnabled()
    }
    
    func toggleSortOrder() {
        guard let model = sortFilterModel else {
            return
        }

        let update = !model.sortByOrderAscending
        do {
            logger.debug("toggleSortOrder: \(update)")
            model.sortByOrderAscending = update
            try model.update(setters: SortFilterSettings.sortByOrderAscendingField.description <- update)
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
            model.discussionFilterBy = filter
            try model.update(setters: SortFilterSettings.discussionFilterByField.description <- filter)
            setFilterIcons()
            updateFiltersEnabled()
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
    
    // If the screen isn't showing all media, I want a visual indication of that.
    private func updateFiltersEnabled() {
        guard let model = sortFilterModel else {
            return
        }
        
        var enabled = false
        
        switch model.discussionFilterBy {
        case .none:
            break
        case .onlyUnread:
            enabled = true
        }
        
        if filtersEnabled != enabled {
            filtersEnabled = enabled
        }
    }
}
