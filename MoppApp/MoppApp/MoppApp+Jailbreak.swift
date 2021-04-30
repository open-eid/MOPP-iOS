//
//  Jailbreak.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */
extension MoppApp {
    var isDeviceJailbroken: Bool {
    
        #if targetEnvironment(simulator) || DEBUG
        // Ignore simulator and DEBUG mode
        return false
        #else

        let jailbreakFiles = [
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Applications/Cydia.app",
            "/private/var/lib/apt/",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt"
        ]
        
        if jailbreakFiles.contains(where: { return FileManager.default.fileExists(atPath: $0) }) {
            // can access one of the files common to jailbroken devices
            return true
        }
        
        do {
            let testData = "test"
            try testData.write(toFile:"/private/jailbreaktestfile.txt", atomically:true, encoding:.utf8)
            // can write to system folder means jailbroken device
            return true
        } catch {
            return false
        }
        
        #endif
    }
}
