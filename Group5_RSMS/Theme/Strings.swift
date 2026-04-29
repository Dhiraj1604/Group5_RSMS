//
//  Strings.swift
//  Group5_RSMS
//

import SwiftUI

enum RSMSStrings {
    
    // MARK: - General / Common
    enum General {
        static let save = LocalizedStringKey("general.save")
        static let cancel = LocalizedStringKey("general.cancel")
        static let dismiss = LocalizedStringKey("general.dismiss")
        static let delete = LocalizedStringKey("general.delete")
        static let remove = LocalizedStringKey("general.remove")
        static let confirm = LocalizedStringKey("general.confirm")
        static let edit = LocalizedStringKey("general.edit")
        static let add = LocalizedStringKey("general.add")
        static let error = LocalizedStringKey("general.error")
        static let success = LocalizedStringKey("general.success")
    }
    
    // MARK: - VIP & Events (Sales)
    enum VIPEvents {
        static let tabTitle = LocalizedStringKey("vipevents.tabTitle")
        static let eventsSegment = LocalizedStringKey("vipevents.eventsSegment")
        static let guestsSegment = LocalizedStringKey("vipevents.guestsSegment")
        
        static let upcomingEvents = LocalizedStringKey("vipevents.upcoming")
        static let pastEvents = LocalizedStringKey("vipevents.past")
        static let noEventsYet = LocalizedStringKey("vipevents.noEventsYet")
        
        static let markAsCompleted = LocalizedStringKey("vipevents.markAsCompleted")
        static let markAsOngoing = LocalizedStringKey("vipevents.markAsOngoing")
        static let cancelEvent = LocalizedStringKey("vipevents.cancelEvent")
        static let deleteEvent = LocalizedStringKey("vipevents.deleteEvent")
        
        static let attendanceReport = LocalizedStringKey("vipevents.attendanceReport")
        static let totalInvited = LocalizedStringKey("vipevents.totalInvited")
        static let attended = LocalizedStringKey("vipevents.attended")
    }
    
    // MARK: - Auth
    enum Auth {
        static let login = LocalizedStringKey("auth.login")
        static let logout = LocalizedStringKey("auth.logout")
        static let emailPlaceholder = LocalizedStringKey("auth.emailPlaceholder")
        static let passwordPlaceholder = LocalizedStringKey("auth.passwordPlaceholder")
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = LocalizedStringKey("dashboard.title")
        static let todaySales = LocalizedStringKey("dashboard.todaySales")
        static let targetPacing = LocalizedStringKey("dashboard.targetPacing")
        static let pendingTasks = LocalizedStringKey("dashboard.pendingTasks")
    }
    
    // MARK: - Accessibility
    enum Accessibility {
        
        // MARK: Dynamic Type / Larger Text
        enum DynamicType {
            static let title = LocalizedStringKey("accessibility.dynamicType.title")
            static let description = LocalizedStringKey("accessibility.dynamicType.description")
            static let commonRequirement = LocalizedStringKey("accessibility.dynamicType.commonRequirement")
            
            static let adminReason = LocalizedStringKey("accessibility.dynamicType.adminReason")
            static let boutiqueManagerReason = LocalizedStringKey("accessibility.dynamicType.boutiqueManagerReason")
            static let inventoryControllerReason = LocalizedStringKey("accessibility.dynamicType.inventoryControllerReason")
            
            static let loginPriority = LocalizedStringKey("accessibility.dynamicType.loginPriority")
            static let navigationPriority = LocalizedStringKey("accessibility.dynamicType.navigationPriority")
            static let formsPriority = LocalizedStringKey("accessibility.dynamicType.formsPriority")
            static let errorsPriority = LocalizedStringKey("accessibility.dynamicType.errorsPriority")
            static let primaryButtonsPriority = LocalizedStringKey("accessibility.dynamicType.primaryButtonsPriority")
            static let productDetailsPriority = LocalizedStringKey("accessibility.dynamicType.productDetailsPriority")
            static let stockAlertsPriority = LocalizedStringKey("accessibility.dynamicType.stockAlertsPriority")
            static let confirmationDialogsPriority = LocalizedStringKey("accessibility.dynamicType.confirmationDialogsPriority")
        }
    }
}
