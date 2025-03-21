//
//  MoppLibPinActions.swift
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

import Foundation

public class MoppLibPinActions {

    /**
     * Changes current PUK to new one by using current PUK for verification.
     *
     * @param newPuk       New PUK that will replace current PUK
     * @param oldPuk       Current PUK to be used for verification
     * @param success       Block to be called on successful completion of action
     * @param failure       Block to be called when action fails. Includes error.
     */
    public static func changePuk(to newPuk: String, oldPuk: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        verify(type: .puk, pin: newPuk, verificationCode: oldPuk, success:success, failure: failure) { handler in
            try handler.changeCode(.puk, to: newPuk, verifyCode: oldPuk)
        }
    }

    /**
     * Changes current PIN1 to new one by using current PIN1 for verification.
     *
     * @param newPin1       New PIN1 that will replace current PIN1
     * @param oldPin1       Current PIN1 to be used for verification
     * @param success       Block to be called on successful completion of action
     * @param failure       Block to be called when action fails. Includes error.
     */
    public static func changePin1(to newPin1: String, oldPin1: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        verify(type: .pin1, pin: newPin1, verificationCode: oldPin1, success:success, failure: failure) { handler in
            try handler.changeCode(.pin1, to: newPin1, verifyCode: oldPin1)
        }
    }

    /**
     * Unblocks PIN1 by changing current PIN1.
     *
     * @param puk           Current PUK to be used for verification.
     * @param newPin1       New PIN1 that will replace current PIN1.
     * @param success       Block to be called on successful completion of action.
     * @param failure       Block to be called when action fails. Includes error.
     */
    public static func unblockPin1(usingPuk puk: String, newPin1: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        verify(type: .pin1, pin: newPin1, verificationCode: puk, success:success, failure: failure) { handler in
            try handler.unblockCode(.pin1, puk: puk, newCode: newPin1)
        }
    }

    /**
     * Changes current PIN2 to new one by using current PIN2 for verification.
     *
     * @param newPin2       New PI21 that will replace current PIN2.
     * @param oldPin2       Current PIN2 to be used for verification.
     * @param success       Block to be called on successful completion of action.
     * @param failure       Block to be called when action fails. Includes error.
     */
    public static func changePin2(to newPin2: String, oldPin2: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        verify(type: .pin2, pin: newPin2, verificationCode: oldPin2, success:success, failure: failure) { handler in
            try handler.changeCode(.pin2, to: newPin2, verifyCode: oldPin2)
        }
    }

    /**
     * Unblocks PIN2 by changing current PIN2.
     *
     * @param puk           Current PUK to be used for verification.
     * @param newPin2       New PIN2 that will replace current PIN2.
     * @param success       Block to be called on successful completion of action.
     * @param failure       Block to be called when action fails. Includes error.
     */
    public static func unblockPin2(usingPuk puk: String, newPin2: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        verify(type: .pin2, pin: newPin2, verificationCode: puk, success:success, failure: failure) { handler in
            try handler.unblockCode(.pin2, puk: puk, newCode: newPin2)
        }
    }

    private static func verify(type: CodeType, pin: String, verificationCode: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void, action: @escaping (CardCommands) throws -> Void) {
        guard Bundle.main.bundleIdentifier == "ee.ria.digidoc" else {
            return failure(MoppLibError.restrictedAPIError())
        }
        guard pin != verificationCode else {
            return failure(MoppLibError.pinMatchesVerificationCodeError())
        }
        let isNumeric = pin.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        guard isNumeric else {
            return failure(MoppLibError.pinContainsInvalidCharactersError())
        }
        switch (type, pin.count) {
        case (.pin1, let count) where count < pin1MinLength() || count > pin1MaxLength(),
             (.pin2, let count) where count < pin2MinLength() || count > pin2MaxLength(),
             (.puk, let count) where count < pukMinLength() || count > pukMaxLength():
            return failure(MoppLibError.incorrectPinLengthError())
        case (.pin1, _) where forbiddenPin1s().contains(pin),
             (.pin2, _) where forbiddenPin2s().contains(pin),
             (.puk, _) where forbiddenPuks().contains(pin):
            return failure(MoppLibError.tooEasyPinError())
        default: break
        }
        guard let handler = MoppLibCardReaderManager.shared.cardCommandHandler else {
            return failure(MoppLibError.cardNotFoundError())
        }
        do {
            try action(handler)
            success()
        } catch {
            failure(error)
        }
    }

    static func forbiddenPin1s() -> [String] {
        return ["0000", "1234"]
    }

    static func forbiddenPin2s() -> [String] {
        return ["00000", "12345"]
    }

    static func forbiddenPuks() -> [String] {
        return ["00000000", "12345678"]
    }

    static func pukMinLength() -> Int {
        return 8
    }

    static func pukMaxLength() -> Int {
        return 12
    }

    static func pin1MinLength() -> Int {
        return 4
    }

    static func pin2MinLength() -> Int {
        return 5
    }

    static func pin1MaxLength() -> Int {
        return 12
    }

    static func pin2MaxLength() -> Int {
        return 12
    }
}
