//
//  DeathStarMap.swift
//  DeathStarEscape
//
//  Created by Anthony Blackman on 2017-06-21.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

public enum DeathStarWallType {
    case Straight
    case Corner
    case Alcove
    case Filled
    case Empty
    case OutOfBounds
}

public struct DeathStarCell {
    public fileprivate(set) var wallType: DeathStarWallType
    public fileprivate(set) var rotation: CGFloat
    public fileprivate(set) var position: CGPoint
    public fileprivate(set) var isNearDoor: Bool = false
    
    init(char: Character, position: CGPoint) {
        if char == "┼" {
            self.init(wallType: .Filled, rotation: 0.0, position: position)
        } else if char == "┯" {
            self.init(wallType: .Straight, rotation: 0.0, position: position)
        } else if char == "┠" {
            self.init(wallType: .Straight, rotation: 0.5 * CGFloat.pi, position: position)
        } else if char == "┷" {
            self.init(wallType: .Straight, rotation: 1.0 * CGFloat.pi, position: position)
        } else if char == "┨" {
            self.init(wallType: .Straight, rotation: 1.5 * CGFloat.pi, position: position)
        } else if char == "╆" {
            self.init(wallType: .Alcove, rotation: 0.0, position: position)
        } else if char == "╄" {
            self.init(wallType: .Alcove, rotation: 0.5 * CGFloat.pi, position: position)
        } else if char == "╃" {
            self.init(wallType: .Alcove, rotation: 1.0 * CGFloat.pi, position: position)
        } else if char == "╅" {
            self.init(wallType: .Alcove, rotation: 1.5 * CGFloat.pi, position: position)
        } else if char == "┏" {
            self.init(wallType: .Corner, rotation: 0.0, position: position)
        } else if char == "┗" {
            self.init(wallType: .Corner, rotation: 0.5 * CGFloat.pi, position: position)
        } else if char == "┛" {
            self.init(wallType: .Corner, rotation: 1.0 * CGFloat.pi, position: position)
        } else if char == "┓" {
            self.init(wallType: .Corner, rotation: 1.5 * CGFloat.pi, position: position)
        } else if char == "#" {
            self.init(wallType: .OutOfBounds, rotation: 0.0, position: position)
        } else if char == "!" {
            self.init(wallType: .OutOfBounds, rotation: 0.0, position: position)
        } else if char == "=" {
            self.init(wallType: .OutOfBounds, rotation: 0.0, position: position)
        } else {
            self.init(wallType: .Empty, rotation: 0.0, position: position)
        }
    }
    
    public init(wallType: DeathStarWallType, rotation: CGFloat, position: CGPoint) {
        self.wallType = wallType
        self.rotation = rotation
        self.position = position
    }
    
    public static let size = 120.0 as CGFloat
}

public struct DoorConfiguration {
    public let position: CGPoint
    public let isHorizontal: Bool
    public let isPassable: Bool
}

let root2 = (2 as CGFloat).squareRoot()
private enum MovementDirection: UInt8 {
    case none = 0
    case up = 1
    case down = 2
    case left = 3
    case right = 4
    case upLeft = 5
    case upRight = 6
    case downLeft = 7
    case downRight = 8
    
    var oppositeDirection: MovementDirection {
        switch self {
        case .none: return .none
            
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
            
        case .upLeft: return .downRight
        case .upRight: return .downLeft
        case .downLeft: return .upRight
        case .downRight: return .upLeft
        }
    }
    
    
    
    var direction: (xChange: Int, yChange: Int) {
        switch self {
        case .none: return (xChange: 0, yChange: 0)
            
        case .up: return (xChange: 0, yChange: -1)
        case .down: return (xChange: 0, yChange: 1)
        case .left: return (xChange: -1, yChange: 0)
        case .right: return (xChange: 1, yChange: 0)
            
        case .upLeft: return (xChange: -1, yChange: -1)
        case .upRight: return (xChange: 1, yChange: -1)
        case .downLeft: return (xChange: -1, yChange: 1)
        case .downRight: return (xChange: 1, yChange: 1)
        }
    }
    
    var distance: CGFloat {
        switch self {
        case .none:
            return 0.0
        case .up, .down, .left, .right:
            return 1.0
        case .upLeft, .upRight, .downLeft, .downRight:
            return root2
        }
    }
}

public class DeathStarMaze {
    
    public private(set) var cells: [DeathStarCell] = []
    public private(set) var startLocation: CGPoint = .zero
    public private(set) var endLocation: CGPoint = .zero
    public private(set) var stormtrooperPaths: [[CGPoint]] = []
    public private(set) var doorConfigurations: [DoorConfiguration] = []
    public private(set) var checkpoints: [CGPoint] = []
    private var visionGrid: [[Bool]] = []
    private var movementGrid: [[Int]] = []
    private var movementTable: [[MovementDirection]] = []
    private var movementPointCount = 0
    private var name: String
    public private(set) var millenniumFalconLocation: CGPoint? = nil
    
    internal init(name: String, width: Int, height: Int) {
        self.name = name
        
        visionGrid = Array(
            repeating: Array(repeating: false, count: 2 * width),
            count: 2 * height
        )
        
        movementGrid = Array(
            repeating: Array(repeating: -1, count: width),
            count: height
        )
    }
    
    private static func parse(representation: String, name: String) -> (maze: DeathStarMaze, additionalPoints: [Character:CGPoint]) {
        let rowRepresentations = representation.components(separatedBy: "\n")
        
        let characterGrid = rowRepresentations.map { (rowRepresentation: String) -> [Character] in
            return Array<Character>(rowRepresentation)
        }
        
        var additionalPoints = [Character:CGPoint]()
        
        let height = characterGrid.count
        let width = characterGrid.first?.count ?? 0
        let maze = DeathStarMaze(name: name, width: width, height: height)
        
        for (rowIndex,row) in characterGrid.enumerated() {
            for (colIndex,char) in row.enumerated() {
                
                let position = CGPoint(
                    x: (CGFloat(colIndex) + 0.5) * DeathStarCell.size,
                    y: (CGFloat(-rowIndex) - 0.5) * DeathStarCell.size
                )
                
                var cell = DeathStarCell(char: char, position: position)
                
                if char == "!" {
                    let doorConfig = DoorConfiguration(position: position, isHorizontal: false, isPassable: false)
                    cell.isNearDoor = true
                    cell.rotation = 0.5 * CGFloat.pi
                    
                    maze.doorConfigurations.append(doorConfig)
                } else if char == "=" {
                    let doorConfig = DoorConfiguration(position: position, isHorizontal: true, isPassable: false)
                    cell.isNearDoor = true
                    
                    maze.doorConfigurations.append(doorConfig)
                } else if cell.wallType == .Empty {
                    if char == "*" {
                        maze.startLocation = position
                    } else if char == "$" {
                        maze.endLocation = position
                    } else if char == "-" {
                        let doorConfig = DoorConfiguration(position: position, isHorizontal: true, isPassable: true)
                        cell.isNearDoor = true
                        maze.doorConfigurations.append(doorConfig)
                    } else if char == "|" {
                        let doorConfig = DoorConfiguration(position: position, isHorizontal: false, isPassable: true)
                        cell.isNearDoor = true
                        cell.rotation = 0.5 * CGFloat.pi
                        maze.doorConfigurations.append(doorConfig)
                    } else if char != " " {
                        additionalPoints[char] = position
                    }
                }
                
                // Need to know when straight cells are adjacent to doors
                // To know what kind of tile to place
                if cell.wallType == .Straight {
                    for (adjacentRowIndex,adjacentColIndex) in [
                        (rowIndex-1,colIndex),
                        (rowIndex+1,colIndex),
                        (rowIndex, colIndex-1),
                        (rowIndex, colIndex+1)
                        ] {
                            if adjacentRowIndex < 0 || adjacentRowIndex >= height
                                || adjacentColIndex < 0 || adjacentColIndex >= width {
                                continue
                            }
                            
                            let char = characterGrid[adjacentRowIndex][adjacentColIndex]
                            
                            if char == "|" || char == "-" {
                                cell.isNearDoor = true
                            }
                    }
                }
                maze.cells.append(cell)
                
                
                maze.visionGrid[2*rowIndex][2*colIndex]     = "┼┷┨╆╄╅┛".contains(char)
                maze.visionGrid[2*rowIndex][2*colIndex+1]   = "┼┠┷╆╃╅┗".contains(char)
                maze.visionGrid[2*rowIndex+1][2*colIndex]   = "┼┯┨╆╄╃┓".contains(char)
                maze.visionGrid[2*rowIndex+1][2*colIndex+1] = "┼┯┠╄╃╅┏".contains(char)
                if cell.wallType != .Empty {
                    maze.movementGrid[rowIndex][colIndex] = -1
                } else {
                    maze.movementGrid[rowIndex][colIndex] = maze.movementPointCount
                    maze.movementPointCount += 1
                }
            }
        }
        
        if let path = Bundle.main.path(forResource: maze.filename, ofType: maze.fileExtension),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let table = movementTable(fromData: data, pointCount: maze.movementPointCount) {
            
            maze.movementTable = table
        } else {
            print("MISSING MAZE FILE FOR \(name) MAZE!!!")
        }
        
        return (maze: maze, additionalPoints: additionalPoints)
    }
    
    var filename: String {
        return "Maze_Movement_Table_\(name)"
    }
    
    var fileExtension: String {
        return "bin"
    }
    
    fileprivate var adjacentPoints: [(Int,Int,MovementDirection)] {
        var result = [(Int,Int,MovementDirection)]()
        let height = movementGrid.count
        for rowIndex in 0 ..< height {
            let width = movementGrid[rowIndex].count
            for colIndex in 0 ..< width {
                let pointA = movementGrid[rowIndex][colIndex]
                
                if movementGrid[rowIndex][colIndex] == -1 { continue }
                
                if rowIndex + 1 < height{
                    let pointB = movementGrid[rowIndex+1][colIndex]
                    if pointB != -1 {
                        result.append((pointA, pointB, .down))
                    }
                }
                
                if colIndex + 1 < width {
                    let pointB = movementGrid[rowIndex][colIndex+1]
                    if pointB != -1 {
                        result.append((pointA, pointB, .right))
                    }
                }
                
                if rowIndex + 1 < height && colIndex + 1 < height {
                    let pointB = movementGrid[rowIndex+1][colIndex+1]
                    if pointB != -1 {
                        result.append((pointA, pointB, .downRight))
                    }
                }
                
                if rowIndex + 1 < height && colIndex - 1 >= 0 {
                    let pointB = movementGrid[rowIndex+1][colIndex-1]
                    if pointB != -1 {
                        result.append((pointA, pointB, .downLeft))
                    }
                }
            }
        }
        
        return result
    }
    
    static let occupancyCellSize = 0.5 * DeathStarCell.size
    private static func toVisionGridCoordinates(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x / occupancyCellSize, y: -point.y / occupancyCellSize)
    }
    
    private static func fromVisionGridCoordinates(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * occupancyCellSize, y: -point.y * occupancyCellSize)
    }
    
    private static func toMovementGridCoordinates(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x / DeathStarCell.size, y: -point.y / DeathStarCell.size)
    }
    
    private static func fromMovementGridCoordinates(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * DeathStarCell.size, y: -point.y * DeathStarCell.size)
    }
    
    public func doorDidUpdateState(at point: CGPoint, isHorizontal: Bool, isOpen: Bool) {
        let visionPoint = DeathStarMaze.toVisionGridCoordinates(point: point)
        
        let xBase = Int(visionPoint.x + 0.5)
        let yBase = Int(visionPoint.y + 0.5)
        
        let xOffsetMax = isHorizontal ? 2 : 1
        let yOffsetMax = isHorizontal ? 1 : 2
        
        let yMin = max(0, yBase - yOffsetMax)
        let xMin = max(0, xBase - xOffsetMax)
        
        let yMax = min(visionGrid.count-1, yBase + yOffsetMax - 1)
        
        for y in stride(from: yMin, through: yMax, by: 1) {
            let xMax = min(visionGrid[y].count - 1, xBase + xOffsetMax - 1)
            
            for x in stride(from: xMin, through: xMax, by: 1) {
                visionGrid[y][x] = !isOpen
            }
        }
        
        // dump(grid: visionGrid)
    }
    
    public func reset() {
        for doorConfig in doorConfigurations {
            doorDidUpdateState(at: doorConfig.position, isHorizontal: doorConfig.isHorizontal, isOpen: false)
        }
    }
    
    private func dump(grid: [[Bool]]) {
        let gridString = grid.map { (row: [Bool]) -> String in
            return " > " + row.map { (cell: Bool) -> String in
                return cell ? "#" : "."
                }.joined() + " < "
            }.joined(separator: "\n")
        
        print("----------")
        print(gridString)
        print("----------")
    }
    
    public func isVisible(point sceneSink: CGPoint, fromPoint sceneSource: CGPoint) -> Bool {
        let sink = DeathStarMaze.toVisionGridCoordinates(point: sceneSink)
        let source = DeathStarMaze.toVisionGridCoordinates(point: sceneSource)
        
        let xDiff = sink.x - source.x
        let yDiff = sink.y - source.y
        
        let xIndexDiff: Int = xDiff > 0.0 ? 1 : -1
        let yIndexDiff: Int = yDiff > 0.0 ? 1 : -1
        
        let xUnitDiff = CGFloat(xIndexDiff)
        let yUnitDiff = CGFloat(yIndexDiff)
        
        let xOffsetDestination: CGFloat = xDiff > 0.0 ? 1.0 : 0.0
        let yOffsetDestination: CGFloat = yDiff > 0.0 ? 1.0 : 0.0
        
        let distance = hypot(xDiff, yDiff)
        
        // Prevent division by 0 errors
        if distance == 0.0 {
            return true
        }
        
        var fractionMoved = 0.0 as CGFloat
        
        var xIndex = Int(source.x)
        var yIndex = Int(source.y)
        var xOffset = source.x - CGFloat(xIndex)
        var yOffset = source.y - CGFloat(yIndex)
        
        while fractionMoved < 1.0 {
            if yIndex >= 0 && yIndex < visionGrid.count && xIndex >= 0 && xIndex < visionGrid[yIndex].count {
                if visionGrid[yIndex][xIndex] {
                    // Travelled into a wall.
                    return false
                }
            } else {
                // Travelled off the map.
                return false
            }
            
            let xOffsetDiff = xOffsetDestination - xOffset
            let yOffsetDiff = yOffsetDestination - yOffset
            
            let scaledXOffsetDiff = xDiff == 0 ? CGFloat.infinity : xOffsetDiff / xDiff
            let scaledYOffsetDiff = yDiff == 0 ? CGFloat.infinity : yOffsetDiff / yDiff
            
            let movementAmount: CGFloat
            
            if scaledXOffsetDiff < scaledYOffsetDiff {
                movementAmount = scaledXOffsetDiff
                xIndex += xIndexDiff
                xOffset -= xUnitDiff
            }
            else {
                movementAmount = scaledYOffsetDiff
                yIndex += yIndexDiff
                yOffset -= yUnitDiff
            }
            
            let movementX = movementAmount * xDiff
            let movementY = movementAmount * yDiff
            
            xOffset += movementX
            yOffset += movementY
            
            fractionMoved += movementAmount
        }
        
        // Travelled past the sink point without hitting a wall.
        return true
    }
    
    func closestEmptyMovementGridCoordinates(fromPoint point: CGPoint) -> (xIndex: Int, yIndex: Int) {
        let gridPoint = DeathStarMaze.toMovementGridCoordinates(point: point)
        
        // Round to nearest tile cell
        let yBaseIndex = Int(gridPoint.y)
        let xBaseIndex = Int(gridPoint.x)
        
        var xClosestIndex = 0
        var yClosestIndex = 0
        var closestDistance: CGFloat = CGFloat.infinity
        
        let yIndexMin = max(0,yBaseIndex-1)
        let yIndexMax = min(movementGrid.count-1, yBaseIndex+1)
        
        if yIndexMin > yIndexMax { return (xIndex: xBaseIndex, yIndex: yBaseIndex) }
        
        let xIndexMin = max(0,xBaseIndex-1)
        let xIndexMax = min(movementGrid[yIndexMin].count-1, xBaseIndex+1)
        
        if xIndexMin > xIndexMax { return (xIndex: xBaseIndex, yIndex: yBaseIndex) }
        
        for yIndex in yIndexMin ... yIndexMax {
            for xIndex in xIndexMin ... xIndexMax {
                if movementGrid[yIndex][xIndex] == -1 { continue }
                
                let gridPoint = CGPoint(x: CGFloat(xIndex) + 0.5, y: CGFloat(yIndex) + 0.5)
                let snappedPoint = DeathStarMaze.fromMovementGridCoordinates(point: gridPoint)
                let distance = abs(snappedPoint.x - point.x) + abs(snappedPoint.y - point.y)
                
                if distance < closestDistance {
                    closestDistance = distance
                    xClosestIndex = xIndex
                    yClosestIndex = yIndex
                }
            }
        }
        
        return (xIndex: xClosestIndex, yIndex: yClosestIndex)
    }
    
    private static func data(forMovementTable movementTable: [[MovementDirection]]) -> Data {
        let bytes = movementTable.flatMap { row in
            return row.map { $0.rawValue }
        }
        
        let data = Data(bytes: bytes)
        
        return data
    }
    
    private static func movementTable(fromData data: Data, pointCount: Int) -> [[MovementDirection]]? {
        let expectedCount = pointCount*pointCount
        if data.count != expectedCount {
            print("Warning: Loaded maze data has \(data.count) bytes, \(expectedCount) expected.")
            return nil
        }
        
        var movementTable = Array<[MovementDirection]>(
            repeating: Array<MovementDirection>(repeating: .none, count: pointCount),
            count: pointCount
        )
        
        let bytes = [UInt8](data)
        
        var byteIndex = 0
        for i in 0 ..< pointCount {
            for j in 0 ..< pointCount {
                movementTable[i][j] = MovementDirection(rawValue: bytes[byteIndex])!
                byteIndex += 1
            }
        }
        
        return movementTable
    }
    
    private static func generateMovementTable(pointCount: Int, adjacentPoints: [(Int,Int,MovementDirection)]) -> [[MovementDirection]] {
        var distances = [[CGFloat]]()
        var movementTable = Array<[MovementDirection]>(
            repeating: Array<MovementDirection>(repeating: .none, count: pointCount),
            count: pointCount
        )
        
        for pointA in 0 ..< pointCount {
            distances.append([])
            for _ in 0 ..< pointA {
                distances[pointA].append(CGFloat.infinity)
            }
            // pointA is 0 distance from itself
            distances[pointA].append(0)
        }
        
        var wasTableChanged = true
        
        while wasTableChanged {
            wasTableChanged = false
            
            for (pointA, pointB, direction) in adjacentPoints {
                for pointC in 0 ..< pointCount {
                    let ab = direction.distance
                    let ac = distances[max(pointA, pointC)][min(pointA, pointC)]
                    let bc = distances[max(pointB, pointC)][min(pointB, pointC)]
                    
                    if bc + ab < ac {
                        distances[max(pointA, pointC)][min(pointA, pointC)] = bc + ab
                        movementTable[pointA][pointC] = direction
                        movementTable[pointC][pointA] = pointB == pointC ? direction.oppositeDirection : movementTable[pointC][pointB]
                        wasTableChanged = true
                    }
                    
                    if ac + ab < bc {
                        distances[max(pointB, pointC)][min(pointB, pointC)] = ac + ab
                        movementTable[pointB][pointC] = direction.oppositeDirection
                        movementTable[pointC][pointB] = pointA == pointC ? direction : movementTable[pointC][pointA]
                        wasTableChanged = true
                    }
                }
            }
        }
        
        return movementTable
    }
    
    fileprivate struct AStarNode {
        let xIndex: Int
        let yIndex: Int
        let distance: Double
        let parentKey: Int?
    }
    
    // Used as the index in a dictionary for A* below
    private func keyFor(xIndex: Int, yIndex: Int) -> Int {
        return yIndex + xIndex * (visionGrid.count + 2)
    }
    
    public func directionForPath(fromPoint source: CGPoint, toPoint sink: CGPoint) -> CGVector? {
        let sourceIndices = closestEmptyMovementGridCoordinates(fromPoint: source)
        let sinkIndices = closestEmptyMovementGridCoordinates(fromPoint: sink)
        
        guard let targetIndices = indicesForNextPointInPath(sourceIndices: sourceIndices, sinkIndices: sinkIndices) else {
            return nil
        }
        
        let targetPosition: CGPoint
        
        if targetIndices == sourceIndices {
            targetPosition = sink
        } else {
            targetPosition = DeathStarMaze.fromMovementGridCoordinates(
                point: CGPoint(
                    x: CGFloat(targetIndices.xIndex) + 0.5,
                    y: CGFloat(targetIndices.yIndex) + 0.5
                )
            )
        }
        
        let diffX = targetPosition.x - source.x
        let diffY = targetPosition.y - source.y
        
        let distance = hypot(diffX, diffY)
        
        if distance < 0.1 {
            return nil
        }
        
        return CGVector(
            dx: diffX / distance,
            dy: diffY / distance
        )
    }
    
    func indicesForNextPointInPath(sourceIndices: (xIndex: Int, yIndex: Int), sinkIndices: (xIndex: Int, yIndex: Int)) -> (xIndex: Int, yIndex: Int)? {
        if sourceIndices == sinkIndices { return sourceIndices }
        
        let width = movementGrid.first?.count ?? 0
        let height = movementGrid.count
        
        if ( sourceIndices.xIndex < 0
            || sourceIndices.xIndex >= width
            || sourceIndices.yIndex < 0
            || sourceIndices.yIndex >= height
            || sinkIndices.xIndex < 0
            || sinkIndices.xIndex >= width
            || sinkIndices.yIndex < 0
            || sinkIndices.yIndex >= height
            ) {
            return nil
        }
        
        let sourceId = movementGrid[sourceIndices.yIndex][sourceIndices.xIndex]
        let sinkId = movementGrid[sinkIndices.yIndex][sinkIndices.xIndex]
        
        if sourceId == -1 || sinkId == -1 {
            return nil
        }
        
        let direction = movementTable[sourceId][sinkId].direction
        
        return (
            xIndex: sourceIndices.xIndex + direction.xChange,
            yIndex: sourceIndices.yIndex + direction.yChange
        )
    }
    
    public func dumpMovementTableFile() {
        let table = DeathStarMaze.generateMovementTable(pointCount: movementPointCount, adjacentPoints: adjacentPoints)
        
        let data = DeathStarMaze.data(forMovementTable: table)
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsUrl = paths[0] as NSURL
        let fileUrl = documentsUrl.appendingPathComponent("\(filename).\(fileExtension)")!
        try! data.write(to: fileUrl)
        
        print("WROTE MAZE DATA FOR \(name) MAZE TO \(fileUrl.absoluteString)")
    }
    
    private static let testingLeveStringRepresentation = (
          "╆┷┷┷┷╅┼┼┼┼┼┼┼╆┷┷┷┷╅\n"
        + "┨*   ┠╆┷┷┷┷┷╅┨1234┠\n"
        + "┨ ┏┓ ┠┨     ┠┨0┏┓5┠\n"
        + "┨ ┗┛ ┠┨ ┏┯┓ ┠┨ ┗┛6┠\n"
        + "┨    ┠┨ ┗┷┛ ┠┨ 987┠\n"
        + "┨ ┏┯┯╃┨     ┠╄┯┯┓ ┠\n"
        + "┨ ┗┷┷╅╄┯┓ ┏┯╃╆┷┷┛ ┠\n"
        + "┨a   ┠┼┼┨-┠┼┼┨   b┠\n"
        + "╄┯┯┓ ┗┷┷┛ ┗┷┷┛ ┏┓ ┠\n"
        + "┼┼┼┨           ┠┨ ┠\n"
        + "┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯╃┨ ┠\n"
        + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┨ ┠\n"
        + "┼┼┼┼┼┼┼╆┷┷┷┷┷┷┷┷┛ ┠\n"
        + "┼┼┼┼┼┼┼┨       |  ┠\n"
        + "┼┼┼┼┼┼┼┨      ┏┯┓ ┠\n"
        + "┼┼┼┼┼┼┼┨   c  ┗╅┨ ┠\n"
        + "┼┼┼┼┼┼┼┨       ┠┨ ┠\n"
        + "┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯╃┨ ┠\n"
        + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┨ ┠\n"
        + "┼╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛ ┠\n"
        + "┼┨   $           d┠\n"
        + "┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃"
    )
    
    public static let testingMaze: DeathStarMaze = {
        var (maze, additionalPoints) = parse(representation: testingLeveStringRepresentation, name: "Test")
        
        guard let a = additionalPoints["a"],
            let b = additionalPoints["b"],
            let c = additionalPoints["c"],
            let d = additionalPoints["d"],
            let p0 = additionalPoints["0"],
            let p1 = additionalPoints["1"],
            let p2 = additionalPoints["2"],
            let p3 = additionalPoints["3"],
            let p4 = additionalPoints["4"],
            let p5 = additionalPoints["5"],
            let p6 = additionalPoints["6"],
            let p7 = additionalPoints["7"],
            let p8 = additionalPoints["8"],
            let p9 = additionalPoints["9"]
            else { return maze }
        
        maze.stormtrooperPaths.append([a,b])
        maze.stormtrooperPaths.append([b,c,d,c])
        
        maze.stormtrooperPaths.append([p0,p1])
        maze.stormtrooperPaths.append([p1,p2])
        maze.stormtrooperPaths.append([p2,p3])
        maze.stormtrooperPaths.append([p3,p4])
        maze.stormtrooperPaths.append([p4,p5])
        maze.stormtrooperPaths.append([p5,p6])
        maze.stormtrooperPaths.append([p6,p7])
        maze.stormtrooperPaths.append([p7,p8])
        maze.stormtrooperPaths.append([p8,p9])
        
        maze.movementTable = generateMovementTable(pointCount: maze.movementPointCount, adjacentPoints: maze.adjacentPoints)
        
        return maze
    }()
    
    public static let movementMaze: DeathStarMaze = {
        let representation = (
            
              "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷╅╆┷┷┷┷┷┷┷┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷┷┛ ┠┨  F  *   ┗┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╆┷┛    ┠╄┯┯┯┯┯┯┯┓    ┗┷╅┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╆┷┛   ┏┯┯╃┼┼┼┼┼┼┼┼╄┯┯┓   ┗┷╅┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╆┛   ┏┯╃╆┷┷┷┷┷┷┷┷┷┷┷┷╅╄┯┓   ┗╅┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╆┛  ┏┯╃┼┼┨            ┠┼┼╄┯┓  ┗╅┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╆┛  ┏╃┼┼┼┼┨ ┏┯┯┯┯┯┓ ┏┓ ┠┼┼┼┼╄┓  ┗╅┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╆┛   ┗┷┷┷╅┼┨ ┗┷┷┷┷╅┨ ┠┨ ┗┷┷┷┷┷┛   ┗╅┼┼┼┼┼┼\n"
            + "┼┼┼┼┼╆┛        ┠┼┨      ┠┨ ┠┨            ┠┼┼┼┼┼┼\n"
            + "┼┼┼┼╆┛  ┏┯┯┯┯┓ ┠┼╄┯┓ ┏┓ ┠┨ ┠┨ ┏┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼\n"
            + "┼┼┼╆┛  ┏╃┼╆┷┷┛ ┗┷┷┷┛ ┗┛ ┗┛ ┗┛ ┗┷┷┷╅╆┷┷┷┷┷┷┷┷╅┼┼┼\n"
            + "┼┼┼┨ $┏╃┼┼┨                       ┠┨########┠┼┼┼\n"
            + "┼┼╆┛#┏╃┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃┨#┏┯┯┯┯┓#┗╅┼┼\n"
            + "┼┼┨##┠┼╆┷┷┷┷┷┷┷╅╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛#┗┷┷┷╅┨##┠┼┼\n"
            + "┼╆┛#┏╃┼┨#######┠┨########################┠╄┓#┗╅┼\n"
            + "┼┨##┠┼┼┨#┏┯┯┯┓#┠╄┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓#┏┓#┏┯┓#┠┼┨##┠┼\n"
            + "┼┨#┏╃┼┼┨#┠╆┷╅┨#┠╆┷┷┷┷┷┷╅┨#┗┷┷┷┷╅┨#┠┨#┗┷┛#┠┼╄┓#┠┼\n"
            + "╆┛#┠╆┷╅┨#┠┨#┠┨#┠┨######┠┨######┠┨#┠┨#####┠┼┼┨#┗╅\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨#┏┯┯┓#┠╄┯┯┯┯┓#┠┨#┠┨#┏┯┯┯╃┼┼┨##┠\n"
            + "┨ ┏╃┨#┠┨#┗┛#┠┨#┠┨#┠╆┷┛#┗┷┷┷┷╅┨#┠┨#┠┨#┠╆┷┷┷┷╅╄┓#┠\n"
            + "┨#┗┷┛#┠┨####┠┨#┠┨#┠┨########┠┨#┠┨#┠┨#┠┨####┗┷┛#┠\n"
            + "┨#####┠┨#┏┓#┠┨#┠┨#┠┨#┏┯┯┯┯┓#┠┨#┗┛#┗┛#┠┨#┏┓#####┠\n"
            + "┨#┏┓#┏╃┨#┠┨#┠┨#┠┨#┠┨#┠╆┷╅┼┨#┠┨#######┠┨#┠┨#┏┯┓#┠\n"
            + "┨=┠┨=┠┼┨#┠┨#┠┨#┠┨#┠┨#┠┨#┗┷┛#┠┨#┏┯┯┯┯┯╃┨#┠┨#┠┼╄┯╃\n"
            + "┨#┠┨#┠┼┨#┠┨#┠┨#┠┨#┠┨#┠┨#####┠┨#┠╆┷┷┷┷╅┨#┠┨#┠┼╆┷╅\n"
            + "┨#┗┛#┗╅┨#┗┛#┠┨#┠┨#┠┨#┠╄┯┯┯┓#┠┨#┠┨####┠┨#┠┨#┗┷┛#┠\n"
            + "┨#####┠┨####┠┨#┠┨#┗┛#┠┼╆┷┷┛#┠┨#┠┨#┏┓#┠┨#┗┛#####┠\n"
            + "┨#┏┯┓#┠┨#┏┓#┠┨#┠┨####┠┼┨####┠┨#┗┛#┠┨#┠┨####┏┯┓#┠\n"
            + "┨#┗╅┨#┠┨#┠┨#┠┨#┠┨#┏┓#┠┼┨#┏┯┯╃┨####┠┨#┠╄┯┯┯┯╃╆┛#┠\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨#┠┨#┗┷┛#┠╆┷┷┛#┏┓#┠┨#┗┷┷╅┼┼┼┨##┠\n"
            + "╄┓#┠╄┯╃┨#┠┨#┠┨#┠┨#┠┨#####┠┨####┠┨#┗┛####┠┼┼┼┨#┏╃\n"
            + "┼┨#┗┷┷┷┛#┠╄┯╃┨#┠┨#┠╄┯┯┯┯┯╃┨#┏┯┯╃┨####┏┓#┠┼┼╆┛#┠┼\n"
            + "┼┨#######┠╆┷┷┛#┠┨#┗┷┷┷┷┷┷┷┛#┗┷┷┷┛#┏┓#┗┛#┠┼┼┨##┠┼\n"
            + "┼╄┯┯┯┯┯┯┯╃┨####┠┨#################┠┨####┠┼╆┛#┏╃┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┨#┏┯┯╃╄┯┯┯┯┯┯┯┯┯┯┯┓#┏┯┯┯╃┨#┏┯┯╃┼┨##┠┼┼\n"
            + "┼┼┼╆┷┷┷┷┷┷┛#┠╆┷┷┷┷┷┷┷┷┷┷┷┷┷╅┨#┗┷┷┷┷┛#┠┼┼┼╆┛#┏╃┼┼\n"
            + "┼┼┼┨########┠┨#############┠┨########┠┼┼╆┛##┠┼┼┼\n"
            + "┼┼┼╄┓###┏┯┯┯╃┨#┏┯┯┯┯┯┯┯┯┯┓#┠╄┯┯┯┯┯┯┯┯╃┼╆┛##┏╃┼┼┼\n"
            + "┼┼┼┼╄┓##┗┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┷┷┛##┏╃┼┼┼┼\n"
            + "┼┼┼┼┼╄┓##################################┏╃┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╄┓###┏┯┯┯┯┯┓#┏┯┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓###┏╃┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╄┓##┗╅┼┼┼┼┨#┗┷┷┷┷┷┷┷┷┛#┠┼┼┼┼╆┛##┏╃┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╄┓##┗┷╅┼┼┨############┠┼┼╆┷┛##┏╃┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╄┓###┗┷╅┨#┏┯┯┯┯┯┯┯┯┓#┠╆┷┛###┏╃┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╄┯┓###┗┛#┠┼┼┼┼┼┼┼┼┨#┗┛###┏┯╃┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╄┯┓####┗┷┷┷┷┷┷┷┷┛####┏┯╃┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┓############┏┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼"
        )
        
        let (maze, pts) = parse(representation: representation, name: "Move")
        
        maze.millenniumFalconLocation = pts["F"]!
        
        return maze
    }()
    
    public static let stormtrooperMaze: DeathStarMaze = {
        let representation = (
              "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷╅╆┷┷┷┷┷┷┷┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷┷┛#┠┨#########┗┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╆┷┛####┠╄┯┯┯┯┯┯┯┓####┗┷╅┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╆┷┛###┏┯┯╃┼┼┼┼┼┼┼┼╄┯┯┓###┗┷╅┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╆┛###┏┯╃╆┷┷┷┷┷┷┷┷┷┷┷┷╅╄┯┓###┗╅┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╆┛##┏┯╃┼┼┨############┠┼┼╄┯┓##┗╅┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╆┛##┏╃┼┼┼┼┨#┏┯┯┯┯┯┓#┏┓#┠┼┼┼┼╄┓##┗╅┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╆┛###┗┷┷┷╅┼┨#┗┷┷┷┷╅┨#┠┨#┗┷┷┷┷┷┛###┗╅┼┼┼┼┼┼\n"
            + "┼┼┼┼┼╆┛#####!##┠┼┨######┠┨#┠┨############┠┼┼┼┼┼┼\n"
            + "┼┼┼┼╆┛##┏┯┯┯┯┓#┠┼╄┯┓#┏┓#┠┨#┠┨#┏┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼\n"
            + "┼┼┼╆┛##┏╃┼╆┷┷┛#┗┷┷┷┛#┗┛#┗┛#┗┛#┗┷┷┷╅╆┷┷┷┷┷┷┷┷╅┼┼┼\n"
            + "┼┼┼┨ *┏╃┼┼┨#######################┠┨########┠┼┼┼\n"
            + "┼┼╆┛ ┏╃┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃┨#┏┯┯┯┯┓#┗╅┼┼\n"
            + "┼┼┨  ┠┼╆┷┷┷┷┷┷┷╅╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛#┗┷┷┷╅┨##┠┼┼\n"
            + "┼╆┛ ┏╃┼┨       ┠┨########################┠╄┓#┗╅┼\n"
            + "┼┨  ┠┼┼┨ ┏┯┯┯┓ ┠╄┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓#┏┓#┏┯┓#┠┼┨##┠┼\n"
            + "┼┨ ┏╃┼┼┨ ┠╆┷╅┨ ┠╆┷┷┷┷┷┷╅┨#┗┷┷┷┷╅┨#┠┨#┗┷┛#┠┼╄┓#┠┼\n"
            + "╆┛ ┠╆┷╅┨ ┠┨D┠┨ ┠┨######┠┨######┠┨#┠┨#####┠┼┼┨#┗╅\n"
            + "┨  ┠┨A┠┨ ┠┨ ┠┨ ┠┨#┏┯┯┓#┠╄┯┯┯┯┓#┠┨#┠┨#┏┯┯┯╃┼┼┨##┠\n"
            + "┨ ┏╃┨ ┠┨ ┗┛ ┠┨ ┠┨#┠╆┷┛#┗┷┷┷┷╅┨#┠┨#┠┨#┠╆┷┷┷┷╅╄┓#┠\n"
            + "┨ ┗┷┛ ┠┨    ┠┨ ┠┨#┠┨########┠┨#┠┨#┠┨#┠┨####┗┷┛#┠\n"
            + "┨     ┠┨ ┏┓ ┠┨ ┠┨#┠┨#┏┯┯┯┯┓#┠┨#┗┛#┗┛#┠┨#┏┓#####┠\n"
            + "┨ ┏┓ ┏╃┨ ┠┨ ┠┨ ┠┨#┠┨#┠╆┷╅┼┨#┠┨#######┠┨#┠┨#┏┯┓#┠\n"
            + "┨ ┠┨ ┠┼┨ ┠┨ ┠┨ ┠┨#┠┨#┠┨#┗┷┛#┠┨#┏┯┯┯┯┯╃┨#┠┨#┠┼╄┯╃\n"
            + "┨ ┠┨ ┠┼┨ ┠┨ ┠┨ ┠┨#┠┨#┠┨#####┠┨#┠╆┷┷┷┷╅┨#┠┨#┠┼╆┷╅\n"
            + "┨ ┗┛ ┗╅┨ ┗┛ ┠┨ ┠┨#┠┨#┠╄┯┯┯┓#┠┨#┠┨####┠┨#┠┨#┗┷┛#┠\n"
            + "┨     ┠┨    ┠┨ ┠┨#┗┛#┠┼╆┷┷┛#┠┨#┠┨#┏┓#┠┨#┗┛#####┠\n"
            + "┨ ┏┯┓ ┠┨ ┏┓ ┠┨ ┠┨####┠┼┨####┠┨#┗┛#┠┨#┠┨####┏┯┓#┠\n"
            + "┨ ┗╅┨ ┠┨ ┠┨ ┠┨ ┠┨#┏┓#┠┼┨#┏┯┯╃┨####┠┨#┠╄┯┯┯┯╃╆┛#┠\n"
            + "┨  ┠┨B┠┨ ┠┨ ┠┨ ┠┨#┠┨#┗┷┛#┠╆┷┷┛#┏┓#┠┨#┗┷┷╅┼┼┼┨##┠\n"
            + "╄┓ ┠╄┯╃┨ ┠┨C┠┨ ┠┨#┠┨#####┠┨####┠┨#┗┛####┠┼┼┼┨#┏╃\n"
            + "┼┨ ┗┷┷┷┛ ┠╄┯╃┨ ┠┨#┠╄┯┯┯┯┯╃┨#┏┯┯╃┨####┏┓#┠┼┼╆┛#┠┼\n"
            + "┼┨       ┠╆┷┷┛ ┠┨#┗┷┷┷┷┷┷┷┛#┗┷┷┷┛#┏┓#┗┛#┠┼┼┨##┠┼\n"
            + "┼╄┯┯┯┯┯┯┯╃┨###$┠┨#################┠┨####┠┼╆┛#┏╃┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┨#┏┯┯╃╄┯┯┯┯┯┯┯┯┯┯┯┓#┏┯┯┯╃┨#┏┯┯╃┼┨##┠┼┼\n"
            + "┼┼┼╆┷┷┷┷┷┷┛#┠╆┷┷┷┷┷┷┷┷┷┷┷┷┷╅┨#┗┷┷┷┷┛#┠┼┼┼╆┛#┏╃┼┼\n"
            + "┼┼┼┨#####!##┠┨#############┠┨########┠┼┼╆┛##┠┼┼┼\n"
            + "┼┼┼╄┓###┏┯┯┯╃┨#┏┯┯┯┯┯┯┯┯┯┓#┠╄┯┯┯┯┯┯┯┯╃┼╆┛##┏╃┼┼┼\n"
            + "┼┼┼┼╄┓##┗┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┷┷┛##┏╃┼┼┼┼\n"
            + "┼┼┼┼┼╄┓##################################┏╃┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╄┓###┏┯┯┯┯┯┓#┏┯┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓###┏╃┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╄┓##┗╅┼┼┼┼┨#┗┷┷┷┷┷┷┷┷┛#┠┼┼┼┼╆┛##┏╃┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╄┓##┗┷╅┼┼┨############┠┼┼╆┷┛##┏╃┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╄┓###┗┷╅┨#┏┯┯┯┯┯┯┯┯┓#┠╆┷┛###┏╃┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╄┯┓###┗┛#┠┼┼┼┼┼┼┼┼┨#┗┛###┏┯╃┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╄┯┓####┗┷┷┷┷┷┷┷┷┛####┏┯╃┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┓############┏┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼"
        )
        
        let (maze, pts) = parse(representation: representation, name: "Storm")
        
        guard
            let a = pts["A"],
            let b = pts["B"],
            let c = pts["C"],
            let d = pts["D"]
            else { fatalError("Missing points") }
        
        maze.stormtrooperPaths.append([a,b])
        maze.stormtrooperPaths.append([c,d])
        
        return maze
    }()
    
    public static let hackingMaze: DeathStarMaze = {
        
        let representation = (
            
              "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷╅╆┷┷┷┷┷┷┷┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷┷┛#┠┨#########┗┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╆┷┛####┠╄┯┯┯┯┯┯┯┓####┗┷╅┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╆┷┛###┏┯┯╃┼┼┼┼┼┼┼┼╄┯┯┓###┗┷╅┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╆┛###┏┯╃╆┷┷┷┷┷┷┷┷┷┷┷┷╅╄┯┓###┗╅┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╆┛##┏┯╃┼┼┨############┠┼┼╄┯┓##┗╅┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╆┛##┏╃┼┼┼┼┨#┏┯┯┯┯┯┓#┏┓#┠┼┼┼┼╄┓##┗╅┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╆┛###┗┷┷┷╅┼┨#┗┷┷┷┷╅┨#┠┨#┗┷┷┷┷┷┛###┗╅┼┼┼┼┼┼\n"
            + "┼┼┼┼┼╆┛########┠┼┨######┠┨#┠┨############┠┼┼┼┼┼┼\n"
            + "┼┼┼┼╆┛##┏┯┯┯┯┓#┠┼╄┯┓#┏┓#┠┨#┠┨#┏┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼\n"
            + "┼┼┼╆┛##┏╃┼╆┷┷┛#┗┷┷┷┛#┗┛#┗┛#┗┛#┗┷┷┷╅╆┷┷┷┷┷┷┷┷╅┼┼┼\n"
            + "┼┼┼┨##┏╃┼┼┨#######################┠┨     | *┠┼┼┼\n"
            + "┼┼╆┛#┏╃┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃┨ ┏┯┯┯┯┓#┗╅┼┼\n"
            + "┼┼┨##┠┼╆┷┷┷┷┷┷┷╅╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛ ┗┷┷┷╅┨##┠┼┼\n"
            + "┼╆┛#┏╃┼┨#######┠┨A                       ┠╄┓#┗╅┼\n"
            + "┼┨##┠┼┼┨#┏┯┯┯┓#┠╄┯┯┯┯┯┯┯┓ ┏┯┯┯┯┯┓ ┏┓ ┏┯┓ ┠┼┨##┠┼\n"
            + "┼┨#┏╃┼┼┨#┠╆┷╅┨#┠╆┷┷┷┷┷┷╅┨ ┗┷┷┷┷╅┨ ┠┨ ┗┷┛ ┠┼╄┓#┠┼\n"
            + "╆┛#┠╆┷╅┨#┠┨#┠┨#┠┨   F  ┠┨     B┠┨ ┠┨     ┠┼┼┨#┗╅\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨ ┏┯┯┓ ┠╄┯┯┯┯┓ ┠┨ ┠┨ ┏┯┯┯╃┼┼┨##┠\n"
            + "┨#┏╃┨#┠┨#┗┛#┠┨#┠┨ ┠╆┷┛ ┗┷┷┷┷╅┨ ┠┨ ┠┨ ┠╆┷┷┷┷╅╄┓#┠\n"
            + "┨#┗┷┛#┠┨####┠┨#┠┨ ┠┨        ┠┨ ┠┨ ┠┨ ┠┨####┗┷┛#┠\n"
            + "┨#####┠┨#┏┓#┠┨#┠┨E┠┨ ┏┯┯┯┯┓ ┠┨ ┗┛ ┗┛ ┠┨#┏┓##!##┠\n"
            + "┨#┏┓#┏╃┨#┠┨#┠┨#┠┨ ┠┨ ┠╆┷╅┼┨ ┠┨       ┠┨#┠┨#┏┯┓#┠\n"
            + "┨#┠┨#┠┼┨#┠┨#┠┨#┠┨ ┠┨ ┠┨$┗┷┛ ┠┨ ┏┯┯┯┯┯╃┨#┠┨#┠┼╄┯╃\n"
            + "┨#┠┨#┠┼┨#┠┨#┠┨#┠┨ ┠┨ ┠┨  |  ┠┨ ┠╆┷┷┷┷╅┨#┠┨#┠┼╆┷╅\n"
            + "┨#┗┛#┗╅┨#┗┛#┠┨#┠┨ ┠┨G┠╄┯┯┯┓ ┠┨ ┠┨   D┠┨#┠┨#┗┷┛#┠\n"
            + "┨#####┠┨####┠┨#┠┨ ┗┛ ┠┼╆┷┷┛ ┠┨-┠┨ ┏┓ ┠┨#┗┛#####┠\n"
            + "┨#┏┯┓#┠┨#┏┓#┠┨#┠┨    ┠┼┨    ┠┨ ┗┛ ┠┨ ┠┨####┏┯┓#┠\n"
            + "┨#┗╅┨#┠┨#┠┨#┠┨#┠┨ ┏┓ ┠┼┨ ┏┯┯╃┨    ┠┨ ┠╄┯┯┯┯╃╆┛#┠\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨-┠┨ ┗┷┛ ┠╆┷┷┛ ┏┓ ┠┨ ┗┷┷╅┼┼┼┨##┠\n"
            + "╄┓#┠╄┯╃┨#┠┨#┠┨#┠┨ ┠┨     ┠┨    ┠┨ ┗┛    ┠┼┼┼┨#┏╃\n"
            + "┼┨#┗┷┷┷┛#┠╄┯╃┨#┠┨ ┠╄┯┯┯┯┯╃┨ ┏┯┯╃┨    ┏┓ ┠┼┼╆┛#┠┼\n"
            + "┼┨#######┠╆┷┷┛#┠┨ ┗┷┷┷┷┷┷┷┛ ┗┷┷┷┛ ┏┓ ┗┛ ┠┼┼┨##┠┼\n"
            + "┼╄┯┯┯┯┯┯┯╃┨####┠┨                 ┠┨    ┠┼╆┛#┏╃┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┨#┏┯┯╃╄┯┯┯┯┯┯┯┯┯┯┯┓ ┏┯┯┯╃┨ ┏┯┯╃┼┨##┠┼┼\n"
            + "┼┼┼╆┷┷┷┷┷┷┛#┠╆┷┷┷┷┷┷┷┷┷┷┷┷┷╅┨ ┗┷┷┷┷┛ ┠┼┼┼╆┛#┏╃┼┼\n"
            + "┼┼┼┨########┠┨#############┠┨C       ┠┼┼╆┛##┠┼┼┼\n"
            + "┼┼┼╄┓###┏┯┯┯╃┨#┏┯┯┯┯┯┯┯┯┯┓#┠╄┯┯┯┯┯┯┯┯╃┼╆┛##┏╃┼┼┼\n"
            + "┼┼┼┼╄┓##┗┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┛#┗┷┷┷┷┷┷┷┷┷┷┷┛##┏╃┼┼┼┼\n"
            + "┼┼┼┼┼╄┓##################################┏╃┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╄┓###┏┯┯┯┯┯┓#┏┯┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓###┏╃┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╄┓##┗╅┼┼┼┼┨#┗┷┷┷┷┷┷┷┷┛#┠┼┼┼┼╆┛##┏╃┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╄┓##┗┷╅┼┼┨############┠┼┼╆┷┛##┏╃┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╄┓###┗┷╅┨#┏┯┯┯┯┯┯┯┯┓#┠╆┷┛###┏╃┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╄┯┓###┗┛#┠┼┼┼┼┼┼┼┼┨#┗┛###┏┯╃┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╄┯┓####┗┷┷┷┷┷┷┷┷┛####┏┯╃┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┓############┏┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼"
        )
        
        let (maze, pts) = parse(representation: representation, name: "Hack")
        
        guard
            let A = pts["A"],
            let B = pts["B"],
            let C = pts["C"],
            let D = pts["D"],
            let E = pts["E"],
            let F = pts["F"],
            let G = pts["G"]
            else { fatalError("Missing points") }
        
        
        maze.stormtrooperPaths.append([A,B])
        maze.stormtrooperPaths.append([C,D])
        maze.stormtrooperPaths.append([E,F,G])
        
        return maze
    }()
    
    public static let scanningMaze: DeathStarMaze = {
        let representation = (
              "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷╅╆┷┷┷┷┷┷┷┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷┷┛#┠┨#########┗┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╆┷┛####┠╄┯┯┯┯┯┯┯┓####┗┷╅┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╆┷┛###┏┯┯╃┼┼┼┼┼┼┼┼╄┯┯┓###┗┷╅┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╆┛###┏┯╃╆┷┷┷┷┷┷┷┷┷┷┷┷╅╄┯┓###┗╅┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╆┛##┏┯╃┼┼┨############┠┼┼╄┯┓##┗╅┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╆┛##┏╃┼┼┼┼┨#┏┯┯┯┯┯┓#┏┓#┠┼┼┼┼╄┓##┗╅┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╆┛###┗┷┷┷╅┼┨#┗┷┷┷┷╅┨#┠┨#┗┷┷┷┷┷┛###┗╅┼┼┼┼┼┼\n"
            + "┼┼┼┼┼╆┛########┠┼┨######┠┨#┠┨############┠┼┼┼┼┼┼\n"
            + "┼┼┼┼╆┛##┏┯┯┯┯┓#┠┼╄┯┓#┏┓#┠┨#┠┨#┏┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼\n"
            + "┼┼┼╆┛##┏╃┼╆┷┷┛#┗┷┷┷┛#┗┛#┗┛#┗┛#┗┷┷┷╅╆┷┷┷┷┷┷┷┷╅┼┼┼\n"
            + "┼┼┼┨##┏╃┼┼┨#######################┠┨#####| $┠┼┼┼\n"
            + "┼┼╆┛#┏╃┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃┨#┏┯┯┯┯┓ ┗╅┼┼\n"
            + "┼┼┨##┠┼╆┷┷┷┷┷┷┷╅╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛#┗┷┷┷╅┨  ┠┼┼\n"
            + "┼╆┛#┏╃┼┨#######┠┨########################┠╄┓ ┗╅┼\n"
            + "┼┨##┠┼┼┨#┏┯┯┯┓#┠╄┯┯┯┯┯┯┯┓#┏┯┯┯┯┯┓#┏┓#┏┯┓#┠┼┨  ┠┼\n"
            + "┼┨#┏╃┼┼┨#┠╆┷╅┨#┠╆┷┷┷┷┷┷╅┨#┗┷┷┷┷╅┨#┠┨#┗┷┛#┠┼╄┓ ┠┼\n"
            + "╆┛#┠╆┷╅┨#┠┨#┠┨#┠┨######┠┨######┠┨#┠┨#####┠┼┼┨ ┗╅\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨#┏┯┯┓#┠╄┯┯┯┯┓#┠┨#┠┨#┏┯┯┯╃┼┼┨  ┠\n"
            + "┨#┏╃┨#┠┨#┗┛#┠┨#┠┨#┠╆┷┛#┗┷┷┷┷╅┨#┠┨#┠┨#┠╆┷┷┷┷╅╄┓ ┠\n"
            + "┨#┗┷┛#┠┨####┠┨#┠┨#┠┨########┠┨#┠┨#┠┨#┠┨    ┗┷┛ ┠\n"
            + "┨#####┠┨#┏┓#┠┨#┠┨#┠┨#┏┯┯┯┯┓#┠┨#┗┛#┗┛#┠┨ ┏┓     ┠\n"
            + "┨#┏┓#┏╃┨#┠┨#┠┨#┠┨#┠┨#┠╆┷╅┼┨#┠┨#######┠┨H┠┨ ┏┯┓ ┠\n"
            + "┨#┠┨#┠┼┨#┠┨#┠┨#┠┨#┠┨#┠┨#┗┷┛#┠┨#┏┯┯┯┯┯╃┨ ┠┨G┠┼╄┯╃\n"
            + "┨#┠┨#┠┼┨#┠┨#┠┨#┠┨#┠┨#┠┨#####┠┨#┠╆┷┷┷┷╅┨ ┠┨ ┠┼╆┷╅\n"
            + "┨#┗┛#┗╅┨#┗┛#┠┨#┠┨#┠┨#┠╄┯┯┯┓#┠┨#┠┨####┠┨I┠┨ ┗┷┛ ┠\n"
            + "┨#####┠┨####┠┨=┠┨#┗┛#┠┼╆┷┷┛#┠┨#┠┨#┏┓#┠┨ ┗┛     ┠\n"
            + "┨#┏┯┓#┠┨#┏┓#┠┨#┠┨####┠┼┨####┠┨#┗┛#┠┨#┠┨    ┏┯┓ ┠\n"
            + "┨#┗╅┨#┠┨#┠┨#┠┨#┠┨#┏┓#┠┼┨#┏┯┯╃┨####┠┨#┠╄┯┯┯┯╃╆┛ ┠\n"
            + "┨##┠┨#┠┨#┠┨#┠┨#┠┨#┠┨#┗┷┛#┠╆┷┷┛#┏┓#┠┨#┗┷┷╅┼┼┼┨ N┠\n"
            + "╄┓#┠╄┯╃┨#┠┨#┠┨#┠┨#┠┨#####┠┨####┠┨#┗┛####┠┼┼┼┨ ┏╃\n"
            + "┼┨#┗┷┷┷┛#┠╄┯╃┨#┠┨#┠╄┯┯┯┯┯╃┨#┏┯┯╃┨####┏┓#┠┼┼╆┛ ┠┼\n"
            + "┼┨#######┠╆┷┷┛ ┠┨#┗┷┷┷┷┷┷┷┛#┗┷┷┷┛#┏┓#┗┛#┠┼┼┨  ┠┼\n"
            + "┼╄┯┯┯┯┯┯┯╃┨   *┠┨#################┠┨####┠┼╆┛ ┏╃┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┨ ┏┯┯╃╄┯┯┯┯┯┯┯┯┯┯┯┓#┏┯┯┯╃┨#┏┯┯╃┼┨  ┠┼┼\n"
            + "┼┼┼╆┷┷┷┷┷┷┛ ┠╆┷┷┷┷┷┷┷┷┷┷┷┷┷╅┨#┗┷┷┷┷┛#┠┼┼┼╆┛ ┏╃┼┼\n"
            + "┼┼┼┨        ┠┨             ┠┨########┠┼┼╆┛  ┠┼┼┼\n"
            + "┼┼┼╄┓   ┏┯┯┯╃┨ ┏┯┯┯┯┯┯┯┯┯┓ ┠╄┯┯┯┯┯┯┯┯╃┼╆┛  ┏╃┼┼┼\n"
            + "┼┼┼┼╄┓  ┗┷┷┷┷┛ ┗┷┷┷┷┷┷┷┷┷┛ ┗┷┷┷┷┷┷┷┷┷┷┷┛  ┏╃┼┼┼┼\n"
            + "┼┼┼┼┼╄┓      A                   E       ┏╃┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╄┓   ┏┯┯┯┯┯┓ ┏┯┯┯┯┯┯┯┯┓ ┏┯┯┯┯┯┓   ┏╃┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╄┓  ┗╅┼┼┼┼┨ ┗┷┷┷┷┷┷┷┷┛ ┠┼┼┼┼╆┛  ┏╃┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╄┓  ┗┷╅┼┼┨B          F┠┼┼╆┷┛  ┏╃┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╄┓ C ┗┷╅┨ ┏┯┯┯┯┯┯┯┯┓ ┠╆┷┛ D ┏╃┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╄┯┓   ┗┛ ┠┼┼┼┼┼┼┼┼┨ ┗┛   ┏┯╃┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╄┯┓    ┗┷┷┷┷┷┷┷┷┛    ┏┯╃┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┓            ┏┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼"
        )
        
        let (maze, pts) = parse(representation: representation, name: "Scan")
        
        guard let a = pts["A"],
            let b = pts["B"],
            let c = pts["C"],
            let d = pts["D"],
            let e = pts["E"],
            let f = pts["F"],
            let g = pts["G"],
            let h = pts["H"],
            let i = pts["I"]
            else { return maze }
        
        maze.stormtrooperPaths.append([a,b,c])
        maze.stormtrooperPaths.append([d,e,f])
        maze.stormtrooperPaths.append([g,h,i])
        
        return maze
    }()
    
    //
    // ╆ ┷ ╅
    //
    // ┨   ┠
    //
    // ╄ ┯ ╃
    //
    // ┏ ┯ ┓
    //
    // ┠ ┼ ┨
    //
    // ┗ ┷ ┛
    public static let finalMaze: DeathStarMaze = {
        let representation = (
              "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷╅╆┷┷┷┷┷┷┷┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╆┷┷┛b┠┨  $      ┗┷┷╅┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╆┷┛    ┠╄┯┯┯┯┯┯┯┓    ┗┷╅┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╆┷┛   ┏┯┯╃┼┼┼┼┼┼┼┼╄┯┯┓   ┗┷╅┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╆┛   ┏┯╃╆┷┷┷┷┷┷┷┷┷┷┷┷╅╄┯┓   ┗╅┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╆┛  ┏┯╃┼┼┨        5  6┠┼┼╄┯┓  ┗╅┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╆┛  ┏╃┼┼┼┼┨ ┏┯┯┯┯┯┓ ┏┓ ┠┼┼┼┼╄┓  ┗╅┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╆┛   ┗┷┷┷╅┼┨ ┗┷┷┷┷╅┨ ┠┨ ┗┷┷┷┷┷┛   ┗╅┼┼┼┼┼┼\n"
            + "┼┼┼┼┼╆┛        ┠┼┨  3  2┠┨ ┠┨            ┠┼┼┼┼┼┼\n"
            + "┼┼┼┼╆┛  ┏┯┯┯┯┓ ┠┼╄┯┓ ┏┓ ┠┨ ┠┨ ┏┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼\n"
            + "┼┼┼╆┛  ┏╃┼╆┷┷┛ ┗┷┷┷┛ ┗┛ ┗┛ ┗┛ ┗┷┷┷╅╆┷┷┷┷┷┷┷┷╅┼┼┼\n"
            + "┼┼┼┨  ┏╃┼┼┨         Z  1  4  7    ┠┨     | q┠┼┼┼\n"
            + "┼┼╆┛ ┏╃┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯┯╃┨ ┏┯┯┯┯┓ ┗╅┼┼\n"
            + "┼┼┨ a┠┼╆┷┷┷┷┷┷┷╅╆┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┷┛ ┗┷┷┷╅┨  ┠┼┼\n"
            + "┼╆┛ ┏╃┼┨       ┠┨J                  K    ┠╄┓ ┗╅┼\n"
            + "┼┨  ┠┼┼┨ ┏┯┯┯┓ ┠╄┯┯┯┯┯┯┯┓ ┏┯┯┯┯┯┓ ┏┓ ┏┯┓ ┠┼┨  ┠┼\n"
            + "┼┨ ┏╃┼┼┨ ┠╆┷╅┨ ┠╆┷┷┷┷┷┷╅┨ ┗┷┷┷┷╅┨ ┠┨ ┗┷┛ ┠┼╄┓ ┠┼\n"
            + "╆┛ ┠╆┷╅┨ ┠┨ ┠┨ ┠┨      ┠┨      ┠┨ ┠┨     ┠┼┼┨ ┗╅\n"
            + "┨  ┠┨ ┠┨ ┠┨ ┠┨ ┠┨ ┏┯┯┓ ┠╄┯┯┯┯┓ ┠┨ ┠┨ ┏┯┯┯╃┼┼┨ M┠\n"
            + "┨ ┏╃┨ ┠┨ ┗┛ ┠┨ ┠┨ ┠╆┷┛ ┗┷┷┷┷╅┨ ┠┨ ┠┨ ┠╆┷┷┷┷╅╄┓ ┠\n"
            + "┨ ┗┷┛ ┠┨    ┠┨ ┠┨ ┠┨A      B┠┨ ┠┨ ┠┨ ┠┨    ┗┷┛ ┠\n"
            + "┨     ┠┨ ┏┓ ┠┨ ┠┨ ┠┨ ┏┯┯┯┯┓ ┠┨ ┗┛ ┗┛ ┠┨ ┏┓     ┠\n"
            + "┨ ┏┓X┏╃┨ ┠┨ ┠┨ ┠┨ ┠┨ ┠╆┷╅┼┨ ┠┨I     L┠┨ ┠┨ ┏┯┓ ┠\n"
            + "┨ ┠┨ ┠┼┨ ┠┨ ┠┨ ┠┨ ┠┨ ┠┨*┗┷┛ ┠┨ ┏┯┯┯┯┯╃┨ ┠┨ ┠┼╄┯╃\n"
            + "┨Y┠┨ ┠┼┨ ┠┨ ┠┨ ┠┨ ┠┨ ┠┨  |  ┠┨ ┠╆┷┷┷┷╅┨ ┠┨ ┠┼╆┷╅\n"
            + "┨ ┗┛ ┗╅┨ ┗┛ ┠┨ ┠┨ ┠┨ ┠╄┯┯┯┓ ┠┨ ┠┨ H  ┠┨ ┠┨ ┗┷┛ ┠\n"
            + "┨     ┠┨    ┠┨ ┠┨ ┗┛ ┠┼╆┷┷┛ ┠┨-┠┨ ┏┓ ┠┨ ┗┛     ┠\n"
            + "┨ ┏┯┓ ┠┨ ┏┓ ┠┨ ┠┨    ┠┼┨    ┠┨ ┗┛ ┠┨ ┠┨    ┏┯┓ ┠\n"
            + "┨ ┗╅┨ ┠┨ ┠┨ ┠┨ ┠┨ ┏┓ ┠┼┨ ┏┯┯╃┨    ┠┨ ┠╄┯┯┯┯╃╆┛ ┠\n"
            + "┨  ┠┨W┠┨r┠┨ ┠┨ ┠┨-┠┨ ┗┷┛ ┠╆┷┷┛ ┏┓ ┠┨ ┗┷┷╅┼┼┼┨ N┠\n"
            + "╄┓ ┠╄┯╃┨V┠┨ ┠┨ ┠┨ ┠┨D   C┠┨    ┠┨ ┗┛    ┠┼┼┼┨ ┏╃\n"
            + "┼┨ ┗┷┷┷┛ ┠╄┯╃┨ ┠┨ ┠╄┯┯┯┯┯╃┨E┏┯┯╃┨    ┏┓G┠┼┼╆┛ ┠┼\n"
            + "┼┨       ┠╆┷┷┛ ┠┨ ┗┷┷┷┷┷┷┷┛ ┗┷┷┷┛ ┏┓ ┗┛ ┠┼┼┨  ┠┼\n"
            + "┼╄┯┯┯┯┯┯┯╃┨   U┠┨                 ┠┨    ┠┼╆┛ ┏╃┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┨ ┏┯┯╃╄┯┯┯┯┯┯┯┯┯┯┯┓ ┏┯┯┯╃┨ ┏┯┯╃┼┨  ┠┼┼\n"
            + "┼┼┼╆┷┷┷┷┷┷┛ ┠╆┷┷┷┷┷┷┷┷┷┷┷┷┷╅┨ ┗┷┷┷┷┛ ┠┼┼┼╆┛ ┏╃┼┼\n"
            + "┼┼┼┨        ┠┨      S      ┠┨    F   ┠┼┼╆┛  ┠┼┼┼\n"
            + "┼┼┼╄┓   ┏┯┯┯╃┨ ┏┯┯┯┯┯┯┯┯┯┓ ┠╄┯┯┯┯┯┯┯┯╃┼╆┛  ┏╃┼┼┼\n"
            + "┼┼┼┼╄┓  ┗┷┷┷┷┛ ┗┷┷┷┷┷┷┷┷┷┛ ┗┷┷┷┷┷┷┷┷┷┷┷┛  ┏╃┼┼┼┼\n"
            + "┼┼┼┼┼╄┓          T      R                ┏╃┼┼┼┼┼\n"
            + "┼┼┼┼┼┼╄┓   ┏┯┯┯┯┯┓ ┏┯┯┯┯┯┯┯┯┓ ┏┯┯┯┯┯┓   ┏╃┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼╄┓  ┗╅┼┼┼┼┨ ┗┷┷┷┷┷┷┷┷┛ ┠┼┼┼┼╆┛  ┏╃┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼╄┓  ┗┷╅┼┼┨Q          P┠┼┼╆┷┛  ┏╃┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼╄┓   ┗┷╅┨ ┏┯┯┯┯┯┯┯┯┓ ┠╆┷┛   ┏╃┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼╄┯┓   ┗┛ ┠┼┼┼┼┼┼┼┼┨ ┗┛   ┏┯╃┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼╄┯┓    ┗┷┷┷┷┷┷┷┷┛    ┏┯╃┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┓      O     ┏┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼\n"
            + "┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼╄┯┯┯┯┯┯┯┯┯┯┯┯╃┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼"
        )
        
        let (maze, pts) = parse(representation: representation, name: "Final")
        
        for pathString in [
            "ABCD",
            "EFGH",
            "IJKL",
            "MN",
            "OPQ",
            "RST",
            "UV",
            "WXY",
            "ab",
            "Z123",
            "4567",
            "7456"
            ] {
                var path = [CGPoint]()
                for char in pathString {
                    path.append(pts[char]!)
                }
                maze.stormtrooperPaths.append(path)
        }
        
        for char in "qr" {
            maze.checkpoints.append(pts[char]!)
        }
        
        maze.millenniumFalconLocation = maze.endLocation
        
        return maze
    }()
    
}
