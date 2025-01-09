//
//  Brainfuckerv2.swift
//  Brainfucker
//
//  Created on 1/9/25.
//

import Foundation

extension String {
    func getChar(at index: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: index)
        let end = self.index(self.startIndex, offsetBy: index + 1)
        return String(self[start..<end])
    }
    
    func substring(from: Int, to: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: from)
        let end = self.index(self.startIndex, offsetBy: to)
        return String(self[start..<end])
    }
}

enum TokenType {
    case Add
    case Subtract
    case Inc
    case Dec
    case JumpIfZero
    case JumpIfNotZero
    case Output
    case Input
}

protocol BFToken {
    var type: TokenType { get set }
    var line: Int { get set }
    var lexeme: String {get set }
}

struct MathToken: BFToken {
    var type: TokenType
    var size: Int
    var line: Int
    var lexeme: String
}

struct JumpToken:BFToken {
    var type: TokenType
    var destination: Int
    var line: Int
    var lexeme: String
}
struct IOToken:BFToken {
    var type: TokenType
    var line: Int
    var lexeme: String
}

let tokenMap: [Character: TokenType] = [
    "+": .Add, "-": .Subtract, "<": .Dec, ">": .Inc,
    "[": .JumpIfZero, "]": .JumpIfNotZero,
    ".": .Output, ",": .Input
]

class Brainfuckerv2 {
    var program: String
    var tokenList: [BFToken] = []
    var idx: Int = 0
    
    init(program: String) {
        self.program = program
    }
    
    func run() {
        firstPass()
        secondPass()
        interpret()
    }
    
    func firstPass() {
        var line = 1
        
        while idx < program.count {
            let cur = program.index(program.startIndex, offsetBy: idx)
            
            switch program[cur] {
            case "+", "-", ">", "<":
                var count = 1
                var new_idx = idx + 1
                var new_cur = program.index(program.startIndex, offsetBy: new_idx)
                let stop_sym = Set("+-><][.,").subtracting([program[cur]])
                while new_idx < program.count && !stop_sym.contains(program[new_cur]) {
                    if program[new_cur] == "\n" { line += 1 }
                    if (program[new_cur] == program[cur]) { count += 1 }
                    new_idx += 1
                    new_cur = program.index(program.startIndex, offsetBy: new_idx)
                }
                tokenList.append(MathToken(type: tokenMap[program[cur]]!, size: count, line: line, lexeme: program.substring(from: idx, to: new_idx)))
                idx = new_idx
            case "[", "]":
                tokenList.append(JumpToken(type: tokenMap[program[cur]]!, destination: -1, line: line, lexeme: String(program[cur])))
                idx += 1
            case ".", ",":
                tokenList.append(IOToken(type: tokenMap[program[cur]]!, line: line, lexeme: String(program[cur])))
                idx += 1
            case "\n":
                line += 1
                idx += 1
            default:
                idx += 1
            }
        }
    }
    
    func secondPass() {
        var stack: [Int] = []
        for (idx, token) in tokenList.enumerated() {
            if token.type == .JumpIfZero {
                stack.append(idx)
            }
            else if token.type == .JumpIfNotZero {
                if let match = stack.popLast() {
                    var closer = tokenList[match] as! JumpToken
                    var opener = tokenList[idx] as! JumpToken
                    closer.destination = idx
                    opener.destination = match
                    
                    tokenList[match] = closer
                    tokenList[idx] = opener
                } else {
                    fatalError("Unmatched bracket at line \(token.line)")
                }
            }
        }
        if !stack.isEmpty {
            fatalError("Unmatched brackets left over from line \(tokenList[stack[0]].line)")
        }
    }
    
    func interpret() {
        var instructionPointer = 0
        var dataPointer = 0
        let MAX_MEM = 30_000
        var memory: [Int] = Array(repeating: 0, count: MAX_MEM)
        var output: [Int] = []
        
        while instructionPointer < tokenList.count {
            switch tokenList[instructionPointer] {
            case let token as MathToken:
                switch token.type {
                case .Add: memory[dataPointer] += token.size
                case .Subtract: memory[dataPointer] -= token.size
                case .Inc: dataPointer = (dataPointer + token.size) //% MAX_MEM
                case .Dec: dataPointer -= token.size
                default: break
                }
                instructionPointer += 1
            case let token as IOToken:
                if token.type == .Input {
                    memory[dataPointer] = Int(getchar())
                } else if token.type == .Output {
                    output.append(memory[dataPointer])
                }
                instructionPointer += 1
            case let token as JumpToken:
                if token.type == .JumpIfZero && memory[dataPointer] == 0 {
                    instructionPointer = token.destination
                } else if token.type == .JumpIfNotZero && memory[dataPointer] != 0 {
                    instructionPointer = token.destination
                } else {
                    instructionPointer += 1
                }
            default:
                break
            }
        }
        do {
            let scalars = try output.map {UnicodeScalar($0)!}
            print(scalars.map{String($0)}.joined())
        } catch {
            print(output)
        }
    }
}
