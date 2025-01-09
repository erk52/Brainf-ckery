//
//  main.swift
//  Brainfucker
//
//  Created by Edward Kish on 1/8/25.
//

import Foundation

var instructionPointer = 0
var dataPointer = 0
let MAX_MEM = 30_000

var memory: [Int] = Array(repeating: 0, count: MAX_MEM)

var output: [Int] = []

//More complicated hello world test pattern
var program_string = """
>++++++++[-<+++++++++>]<.>>+>-[+]++
>++>+++[>[->+++<<+++>]<<]>-----.>->
+++..+++.>-.<<+[>[+>+]>>]<---------
-----.>>.+++.------.--------.>+.>+.
"""

if CommandLine.arguments.count == 2 {
    let filename = CommandLine.arguments[1]
    program_string = try! String(contentsOfFile: filename)
} else {
    print("Please provide a single command line argument (path to bf file)")
}
let program = Array(program_string)


while instructionPointer < program.count {
    switch program[instructionPointer] {
    case "+": memory[dataPointer] += 1
    case "-": memory[dataPointer] -= 1
    case ">": dataPointer += 1
    case "<": dataPointer -= 1
    case "[":
        if memory[dataPointer] == 0 {
            var open = 1
            while open > 0 {
                instructionPointer += 1
                if program[instructionPointer] == "[" { open += 1}
                if program[instructionPointer] == "]" { open -= 1}
            }
        }
    case "]":
        if memory[dataPointer] != 0 {
            var open = 1
            while open > 0 {
                instructionPointer -= 1
                if program[instructionPointer] == "[" { open -= 1}
                if program[instructionPointer] == "]" { open += 1}
            }
        }
    case ".":
        output.append(memory[dataPointer])
    case ",":
        memory[dataPointer] = Int(getchar())
    default:
        break
    }
    if dataPointer < 0 { dataPointer = MAX_MEM - 1}
    if dataPointer == MAX_MEM { dataPointer = 0 }
    instructionPointer += 1
}

do {
    let scalars = try output.map {UnicodeScalar($0)!}
    print(scalars.map{String($0)}.joined())
} catch {
    print(output)
}
