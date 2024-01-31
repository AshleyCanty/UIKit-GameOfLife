//
//  ViewController.swift
//  UIKit-GameOfLife
//
//  Created by ashley canty on 1/26/24.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let game = Game()
    private let reuseId = "Cell"
    private var didSetSeed = false
    
    private let padding: CGFloat = 20.0
    private lazy var itemWidth: CGFloat = {
        let itemWidthNotRounded = (view.bounds.width - (padding*2.0))/Game.dimension
        return itemWidthNotRounded.rounded(.toNearestOrEven)
    }()
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 1.0
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isScrollEnabled = false
        collection.delegate = self
        collection.dataSource = self
        collection.allowsMultipleSelection = true
        collection.isMultipleTouchEnabled = true
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        return collection
    }()
    
    private lazy var configureButton: ((UIButton, String, String) -> Void) = { btn, title, imageName in
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.35)
        config.attributedTitle?.foregroundColor = .white
        config.image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(scale: .small))
        config.imagePadding = 4
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        btn.configuration = config
    }
    
    private lazy var hStack: UIStackView = {
       let stack = UIStackView(arrangedSubviews: [restartButton, nextStepButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        stack.distribution = .equalCentering
        return stack
    }()
    
    private lazy var nextStepButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.isEnabled = false
        configureButton(btn, "Next step", "arrowtriangle.right.fill")
        return btn
    }()
    
    private lazy var restartButton: UIButton = {
        let btn = UIButton(type: .system)
        configureButton(btn, "Clear", "trash.fill")
        return btn
    }()
    
    private var generationLabel: UILabel = {
       let label = UILabel()
        label.textColor = .white
        label.text = "Generation: 0"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private var generationCount: Int = 0 {
        didSet {
            generationLabel.text = "Generation: \(generationCount)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        generateNewLife()
    }

    private func setupViews() {
        view.backgroundColor = .systemCyan
        
        view.addSubview(generationLabel)
        view.addSubview(collection)
        view.addSubview(hStack)
        
        generationLabel.translatesAutoresizingMaskIntoConstraints = false
        generationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        generationLabel.bottomAnchor.constraint(equalTo: collection.topAnchor, constant: -25).isActive = true
        
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        collection.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        /// Accounts for item size and the gaps from minimumInteritemSpacing & minimumLineSpacing
        let collectionWidth = (itemWidth*Game.dimension) + Game.dimension
        collection.widthAnchor.constraint(equalToConstant: collectionWidth).isActive = true
        collection.heightAnchor.constraint(equalToConstant: collectionWidth).isActive = true
        
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hStack.topAnchor.constraint(equalTo: collection.bottomAnchor, constant: 50).isActive = true
        
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.widthAnchor.constraint(equalToConstant: 150).isActive = true
        restartButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        nextStepButton.translatesAutoresizingMaskIntoConstraints = false
        nextStepButton.widthAnchor.constraint(equalToConstant: 150).isActive = true
        nextStepButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        /// Targets and Gesture Recognizers
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        nextStepButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        panGesture.delegate = self
        tapGesture.delegate = self
        
        collection.addGestureRecognizer(panGesture)
        collection.addGestureRecognizer(tapGesture)
    }
    
    @objc private func generateNewLife() {
        game.iterate { [weak self] didCompleteGeneration in
            guard let self = self, didCompleteGeneration else { return }
            collection.reloadData()
        }
    }
    
    @objc private func restartGame() {
        game.resetStates { [weak self] in
            guard let self = self else { return }
            self.collection.reloadData()
            nextStepButton.isEnabled = false
            didSetSeed = false
            generationCount = 0
        }
    }
    
    @objc private func didTapNextButton() {
        if !didSetSeed { didSetSeed = true }
        generateNewLife()
        generationCount += 1
    }

    @objc func didTap(sender: UITapGestureRecognizer) {
        updateCellState(with: sender.location(in: collection))
    }
    
    @objc func didPan(sender: UIPanGestureRecognizer) {
        updateCellState(with: sender.location(in: collection))
    }
    
    /// Only updates cell states if the seed has not already been set
    private func updateCellState(with touchPoint: CGPoint) {
        guard !didSetSeed else { return }
        
        nextStepButton.isEnabled = true
        game.validateTouchpoint(touchPoint: touchPoint) { [weak self] selectedIndex in
            guard let self = self, let index = selectedIndex else { return }
            collection.reloadItems(at: [index])
        }
    }
}

// MARK: - UICollection View Delegate methods

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return game.cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath)
        
        let cell = game.cells[indexPath.item]
        cell.set(indexPath, collectionCell.frame)
        
        collectionCell.contentView.backgroundColor = cell.isAlive ? .systemGreen : .white
        return collectionCell
    }
}
