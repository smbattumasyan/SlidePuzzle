//
//  Match3Scene.swift
//  SlidePuzzle
//
//  Presentation layer for the match-3 board. Holds no game rules:
//  it forwards swaps to Match3Board and replays the returned CascadeSteps
//  as SKActions.
//

import SpriteKit

final class Match3Scene: SKScene {

    private let board: Match3Board
    private let gameState: Match3GameState

    private let tileSize: CGFloat = 100
    private let tilePadding: CGFloat = 4

    /// sprites[col][row]; row 0 is the bottom row.
    private var sprites: [[SKSpriteNode?]] = []
    private var gridNode = SKNode()
    private var selectionHighlight: SKShapeNode?

    // Input tracking
    private var touchStartPosition: GridPosition?
    private var touchStartLocation: CGPoint = .zero
    private var selectedPosition: GridPosition?

    // MARK: - Init

    init(gameState: Match3GameState, board: Match3Board) {
        self.gameState = gameState
        self.board = board
        let side = CGFloat(max(board.columns, board.rows)) * tileSize + 60
        super.init(size: CGSize(width: side, height: side))
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.72, green: 0.80, blue: 0.58, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        buildBoard()
    }

    // MARK: - Board construction

    private func buildBoard() {
        gridNode.removeFromParent()
        gridNode = SKNode()
        gridNode.position = CGPoint(
            x: -CGFloat(board.columns) * tileSize / 2,
            y: -CGFloat(board.rows) * tileSize / 2
        )
        addChild(gridNode)

        sprites = Array(repeating: Array(repeating: nil, count: board.rows),
                        count: board.columns)
        for (position, type) in board.currentLayout() {
            addSprite(for: type, at: position)
        }
    }

    @discardableResult
    private func addSprite(for type: TileType, at position: GridPosition) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: type.assetName)
        sprite.size = CGSize(width: tileSize - tilePadding, height: tileSize - tilePadding)
        sprite.position = point(for: position)
        sprite.zPosition = 10
        gridNode.addChild(sprite)
        sprites[position.col][position.row] = sprite
        return sprite
    }

    private func point(for position: GridPosition) -> CGPoint {
        CGPoint(x: CGFloat(position.col) * tileSize + tileSize / 2,
                y: CGFloat(position.row) * tileSize + tileSize / 2)
    }

    private func gridPosition(at location: CGPoint) -> GridPosition? {
        let local = convert(location, to: gridNode)
        let col = Int(floor(local.x / tileSize))
        let row = Int(floor(local.y / tileSize))
        let position = GridPosition(col: col, row: row)
        return board.contains(position) ? position : nil
    }

    // MARK: - Restart

    func restart() {
        gameState.reset()
        clearSelection()
        let layout = board.reshuffle()
        gameState.isResolving = true
        animateReshuffle(to: layout) { [weak self] in
            self?.gameState.isResolving = false
        }
    }

    // MARK: - Touch input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isResolving, let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        touchStartPosition = gridPosition(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isResolving,
              let start = touchStartPosition,
              let touch = touches.first else { return }

        let location = touch.location(in: self)
        let dx = location.x - touchStartLocation.x
        let dy = location.y - touchStartLocation.y
        guard max(abs(dx), abs(dy)) > tileSize / 2 else { return }

        let target: GridPosition
        if abs(dx) > abs(dy) {
            target = GridPosition(col: start.col + (dx > 0 ? 1 : -1), row: start.row)
        } else {
            target = GridPosition(col: start.col, row: start.row + (dy > 0 ? 1 : -1))
        }
        touchStartPosition = nil
        clearSelection()
        performSwap(start, target)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isResolving, let tapped = touchStartPosition else { return }
        touchStartPosition = nil

        if let selected = selectedPosition {
            clearSelection()
            if selected == tapped { return }
            if selected.isAdjacent(to: tapped) {
                performSwap(selected, tapped)
                return
            }
        }
        select(tapped)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPosition = nil
    }

    private func select(_ position: GridPosition) {
        selectedPosition = position
        let highlight = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize),
                                    cornerRadius: 12)
        highlight.strokeColor = .yellow
        highlight.lineWidth = 5
        highlight.zPosition = 20
        highlight.position = point(for: position)
        gridNode.addChild(highlight)
        selectionHighlight = highlight
    }

    private func clearSelection() {
        selectedPosition = nil
        selectionHighlight?.removeFromParent()
        selectionHighlight = nil
    }

    // MARK: - Swap + cascade animation

    private func performSwap(_ a: GridPosition, _ b: GridPosition) {
        guard let spriteA = sprites[a.col][a.row],
              let spriteB = sprites[b.col][b.row] else { return }

        gameState.isResolving = true
        let outcome = board.attemptSwap(a, b)

        let moveAToB = SKAction.move(to: point(for: b), duration: 0.15)
        moveAToB.timingMode = .easeInEaseOut
        let moveBToA = SKAction.move(to: point(for: a), duration: 0.15)
        moveBToA.timingMode = .easeInEaseOut

        switch outcome {
        case .invalid:
            // Slide out and back.
            spriteA.run(.sequence([moveAToB, moveBToA]))
            spriteB.run(.sequence([moveBToA, moveAToB])) { [weak self] in
                self?.gameState.isResolving = false
            }

        case .valid(let steps):
            commitSwapSprites(a, b, spriteA: spriteA, spriteB: spriteB,
                              moveAToB: moveAToB, moveBToA: moveBToA)
            run(.wait(forDuration: 0.18)) { [weak self] in
                self?.replaySteps(steps, index: 0) {
                    self?.gameState.isResolving = false
                }
            }

        case .validThenShuffle(let steps, let newLayout):
            commitSwapSprites(a, b, spriteA: spriteA, spriteB: spriteB,
                              moveAToB: moveAToB, moveBToA: moveBToA)
            run(.wait(forDuration: 0.18)) { [weak self] in
                self?.replaySteps(steps, index: 0) {
                    self?.animateReshuffle(to: newLayout) {
                        self?.gameState.isResolving = false
                    }
                }
            }
        }
    }

    private func commitSwapSprites(_ a: GridPosition, _ b: GridPosition,
                                   spriteA: SKSpriteNode, spriteB: SKSpriteNode,
                                   moveAToB: SKAction, moveBToA: SKAction) {
        spriteA.run(moveAToB)
        spriteB.run(moveBToA)
        sprites[a.col][a.row] = spriteB
        sprites[b.col][b.row] = spriteA
    }

    private func replaySteps(_ steps: [CascadeStep], index: Int, completion: @escaping () -> Void) {
        guard index < steps.count else {
            completion()
            return
        }
        let step = steps[index]
        gameState.score += step.scoreDelta

        // 1. Pop matched tiles.
        let pop = SKAction.group([
            .scale(to: 0.1, duration: 0.2),
            .fadeOut(withDuration: 0.2),
        ])
        for position in step.matched {
            guard let sprite = sprites[position.col][position.row] else { continue }
            sprites[position.col][position.row] = nil
            sprite.run(.sequence([pop, .removeFromParent()]))
        }

        // 2. After the pop, drop survivors and spawn refills.
        run(.wait(forDuration: 0.22)) { [weak self] in
            guard let self else { return }

            var longestDrop: TimeInterval = 0

            for fall in step.falls {
                guard let sprite = self.sprites[fall.from.col][fall.from.row] else { continue }
                self.sprites[fall.from.col][fall.from.row] = nil
                self.sprites[fall.to.col][fall.to.row] = sprite
                let distance = TimeInterval(fall.from.row - fall.to.row)
                let duration = 0.08 * distance + 0.05
                longestDrop = max(longestDrop, duration)
                let move = SKAction.move(to: self.point(for: fall.to), duration: duration)
                move.timingMode = .easeIn
                sprite.run(move)
            }

            for spawn in step.spawns {
                let sprite = self.addSprite(for: spawn.type, at: spawn.at)
                sprite.position = self.point(for: GridPosition(col: spawn.at.col,
                                                               row: spawn.dropFromRow))
                let distance = TimeInterval(spawn.dropFromRow - spawn.at.row)
                let duration = 0.08 * distance + 0.05
                longestDrop = max(longestDrop, duration)
                let move = SKAction.move(to: self.point(for: spawn.at), duration: duration)
                move.timingMode = .easeIn
                sprite.run(move)
            }

            // 3. Next cascade round.
            self.run(.wait(forDuration: longestDrop + 0.08)) {
                self.replaySteps(steps, index: index + 1, completion: completion)
            }
        }
    }

    // MARK: - Reshuffle animation

    private func animateReshuffle(to layout: [GridPosition: TileType],
                                  completion: @escaping () -> Void) {
        gridNode.run(.fadeOut(withDuration: 0.25)) { [weak self] in
            guard let self else { return }
            for column in self.sprites {
                for sprite in column {
                    sprite?.removeFromParent()
                }
            }
            self.sprites = Array(repeating: Array(repeating: nil, count: self.board.rows),
                                 count: self.board.columns)
            for (position, type) in layout {
                self.addSprite(for: type, at: position)
            }
            self.gridNode.run(.fadeIn(withDuration: 0.25)) {
                completion()
            }
        }
    }
}
