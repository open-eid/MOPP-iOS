//
//  ContainerNativeShare.swift
//  MoppApp
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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
protocol NativeShare {
    func shareFile(using url: URL, sender: UIView, completion: ((_ success: Bool) -> Void)?)
}

extension NativeShare where Self: UIViewController {
    func shareFile(using url: URL, sender: UIView, completion: ((_ success: Bool) -> Void)? = nil) {
        let activityItems: [Any] = [url];
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityVC.modalPresentationStyle = .overFullScreen
            activityVC.popoverPresentationController?.sourceView = sender
            activityVC.completionWithItemsHandler = {_ , completed,_ , error in
                completion?(completed && error == nil)
            }
        present(activityVC, animated: true)
    }
}
