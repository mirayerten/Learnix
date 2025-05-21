//
//  Lesson.swift
//  Learnix
//
//  Created by Miray Erten on 21.05.2025.
//

import Foundation

struct Lesson : Codable {
    let id: String
    let lessonName: String
    let teacherName: String
    let teacherEmail: String
    let pdfURL: String?
}
