//
//  CustodyActionState.swift
//  Blockchain
//
//  Created by AlexM on 2/27/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

enum CustodyActionState {
    
    /// The start of the custody-send flow
    case start
    
    /// Custody introduction, should only show based on a
    /// user defaults flag
    case introduction
    
    /// Backup but only if an introduction is shown
    /// otherwise it the state should be `backup`
    case backupAfterIntroduction
    
    /// Starts the `BackupRouter`
    case backup
    
    /// The recovery phrase screen
    case send

    /// Route to activity
    case activity
    
    /// The withdrawal custodial funds screen
    case withdrawal
    
    /// The withdrawal screen but only
    /// if the user just backed up their wallet.
    /// Otherwise the state should be `withdrawal`
    case withdrawalAfterBackup
    
    /// ~Fin~
    case end
}
