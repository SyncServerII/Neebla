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
import Combine

class SortFilterMenuModel: ObservableObject {
    let sortFilterModel: SortFilterSettings?
    @Published var sortOrderChevron: SFSymbol = .chevronUp
    @Published var filtersEnabled: Bool = true
    
    @Published var sort: SortFilterSettings.SortBy = .creationDate {
        didSet {
            guard let model = sortFilterModel else {
                return
            }
        
            if sort == model.sortBy {
                // There was no change in type of sort. Just toggle ascending/descending.
                self.toggleSortOrder()
            }
            else {
                self.select(sort: sort)
            }
        }
    }
    
    @Published var filter: SortFilterSettings.DiscussionFilterBy = .none {
        didSet {
            guard let model = sortFilterModel else {
                return
            }
            
            guard model.discussionFilterBy != filter else {
                return
            }
            
            self.select(filter: filter)
        }
    }
    
    init(sortFilterModel: SortFilterSettings?) {
        self.sortFilterModel = sortFilterModel
        setSortOrderChevron()
        updateFiltersEnabled()
        
        guard let model = sortFilterModel else {
            return
        }
        
        // Initialize the published values without triggering them.
        _filter = .init(initialValue: model.discussionFilterBy)
        _sort = .init(initialValue: model.sortBy)
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
            model.sortByOrderAscendingChanged.send(update)
            setSortOrderChevron()
        } catch let error {
            logger.error("\(error)")
        }
    }

    func select(sort: SortFilterSettings.SortBy) {
        guard let model = sortFilterModel else {
            return
        }
        
        do {
            model.sortBy = sort
            try model.update(setters: SortFilterSettings.sortByField.description <- sort)
            model.sortByChanged.send(sort)
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
            model.discussionFilterByChanged.send(filter)
            updateFiltersEnabled()
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    private func setSortOrderChevron() {
        guard let model = sortFilterModel else {
            return
        }
        sortOrderChevron = model.sortByOrderAscending ? .chevronUp : .chevronDown
    }
    
    // If the screen isn't showing all media, I want a visual indication of that.
    private func updateFiltersEnabled() {
        guard let model = sortFilterModel else {
            return
        }
        
        let enabled = model.filtersEnabled()
        
        if filtersEnabled != enabled {
            filtersEnabled = enabled
        }
    }
}
