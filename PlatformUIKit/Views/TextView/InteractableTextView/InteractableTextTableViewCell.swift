//
//  InteractableTextTableViewCell.swift
//  PlatformUIKit
//
//  Created by Daniel Huri on 19/02/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

public final class InteractableTextTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    
    private var horizontalConstraints: UIView.Axis.Constraints!
    private var verticalConstraints: UIView.Axis.Constraints!
    private let instructionTextView = InteractableTextView()
    
    // MARK: - Injected
    
    public var contentInset = UIEdgeInsets() {
        didSet {
            horizontalConstraints.leading.constant = contentInset.left
            horizontalConstraints.trailing.constant = -contentInset.right
            verticalConstraints.leading.constant = contentInset.top
            verticalConstraints.trailing.constant = -contentInset.bottom
            contentView.layoutIfNeeded()
        }
    }
    
    public var viewModel: InteractableTextViewModel! {
        didSet {
            guard let viewModel = viewModel else { return }
            instructionTextView.viewModel = viewModel
            instructionTextView.setupHeight()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(instructionTextView)
        horizontalConstraints = instructionTextView.layoutToSuperview(axis: .horizontal)
        verticalConstraints = instructionTextView.layoutToSuperview(axis: .vertical)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
}
