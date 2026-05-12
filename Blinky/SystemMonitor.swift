//
//  SystemMonitor.swift
//  Blinky
//

import Foundation
import Combine
import Darwin

class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsage: Double = 0.0 // Percentage
    @Published var ramUsedGB: Double = 0.0
    @Published var ramTotalGB: Double = 0.0
    @Published var diskUsage: Double = 0.0 // Percentage
    @Published var diskUsedGB: Double = 0.0
    @Published var diskTotalGB: Double = 0.0
    @Published var uptimeString: String = ""
    
    private var timer: Timer?
    private var isUpdating: Bool = false
    
    // CPU state
    private var previousInfo: processor_info_array_t?
    private var previousInfoCount: mach_msg_type_number_t = 0
    
    private init() {}
    
    func start() {
        guard !isUpdating else { return }
        isUpdating = true
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func stop() {
        isUpdating = false
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        updateCPU()
        updateRAM()
        updateDisk()
        updateUptime()
    }
    
    private func updateCPU() {
        var numCPUsU: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &info, &infoCount)
        
        if result == KERN_SUCCESS, let info = info {
            let numCPUs = Int(numCPUsU)
            if let prevInfo = previousInfo {
                var totalTicks: Double = 0
                var idleTicks: Double = 0
                
                for i in 0..<numCPUs {
                    let inUse = Double(
                        info[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)] - prevInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)] +
                        info[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)] - prevInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)] +
                        info[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)] - prevInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)]
                    )
                    let total = inUse + Double(info[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)] - prevInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)])
                    
                    totalTicks += total
                    idleTicks += Double(info[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)] - prevInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)])
                }
                
                let usage = totalTicks > 0 ? (totalTicks - idleTicks) / totalTicks : 0
                self.cpuUsage = min(max(usage, 0), 1)
            }
            
            if let prevInfo = previousInfo {
                let prevInfoSize = previousInfoCount * UInt32(MemoryLayout<integer_t>.size)
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevInfo), vm_size_t(prevInfoSize))
            }
            
            previousInfo = info
            previousInfoCount = infoCount
        }
    }
    
    private func updateRAM() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size
            let active = Double(stats.active_count) * Double(pageSize)
            let wired = Double(stats.wire_count) * Double(pageSize)
            let compressed = Double(stats.compressor_page_count) * Double(pageSize)
            
            let used = active + wired + compressed
            
            let physicalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            self.ramTotalGB = physicalMemory / 1_073_741_824
            self.ramUsedGB = used / 1_073_741_824
            self.ramUsage = used / physicalMemory
        }
    }
    
    private func updateDisk() {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            if let capacity = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
                let used = capacity - available
                self.diskTotalGB = Double(capacity) / 1_073_741_824
                self.diskUsedGB = Double(used) / 1_073_741_824
                self.diskUsage = Double(used) / Double(capacity)
            }
        } catch {
            print("Failed to read disk usage: \(error)")
        }
    }
    
    private func updateUptime() {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        
        if days > 0 {
            self.uptimeString = Localization.at("\(days)d \(hours)h", "\(days)d \(hours)h")
        } else {
            let minutes = (Int(uptime) % 3600) / 60
            self.uptimeString = Localization.at("\(hours)h \(minutes)m", "\(hours)h \(minutes)m")
        }
    }
}
