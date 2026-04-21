//
//  BMTasksViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class BMTasksViewModel: ObservableObject {
    @Published var tasks: [StoreTask] = []
    @Published var staff: [Employee] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let sync = SupabaseSyncManager.shared

    func fetchTasksAndStaff(boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // Wait for both
            async let tasksVal = sync.fetchTasks(boutiqueId: boutiqueId)
            async let staffVal = sync.fetchEmployees(boutiqueId: boutiqueId)
            
            let fetchedTasks = (try? await tasksVal) ?? [] 
            let fetchedStaff = (try? await staffVal) ?? []
            
            self.tasks = fetchedTasks
            self.staff = fetchedStaff

        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addTask(_ task: StoreTask) async {
        isLoading = true
        // Optimistic update
        tasks.insert(task, at: 0)
        do {
            try await sync.createTask(task)
        } catch {
            print("Supabase createTask failed (Table might not exist): \(error)")
        }
        isLoading = false
    }

    func toggleTaskCompletion(_ task: StoreTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        
        do {
            try await sync.updateTask(tasks[index])
        } catch {
             print("Supabase updateTask failed: \(error)")
        }
    }
    
    func deleteTask(at offsets: IndexSet) async {
        let tasksToDelete = offsets.map { tasks[$0] }
        tasks.remove(atOffsets: offsets)
        
        for task in tasksToDelete {
            do {
                try await sync.deleteTask(id: task.id)
            } catch {
                print("Supabase deleteTask failed: \(error)")
            }
        }
    }
}
