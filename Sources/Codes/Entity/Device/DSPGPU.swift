import Foundation
import Metal

final class DSPGPU {
    nonisolated(unsafe) static var current: DSPGPU = .init()
    let device: any MTLDevice

    init() {
        device = MTLCreateSystemDefaultDevice()!
    }

    var currentAllocatedSize: Int {
        device.currentAllocatedSize
    }
}
