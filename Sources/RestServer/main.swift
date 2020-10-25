// Name:Xinxue Wang
// CWID: 889218061
// CS411-Assignment 1 10/24/2020

import SQLite
import Kitura
import Foundation

/// Entrance of Kitura
let router = Router()


///
/// Claim Object.
///     For json encode & decode.
///
public struct Claim: Codable {
    var id: UUID?
    let title: String
    let date: String
    var isSolved: Bool?
}

/// this is db connection. TODO: replace the claim db with local db
let db = try Connection("/Users/XinW/Desktop/RestServer/claim.db")

/// declare table schema
let claimTable = Table("claim")
let id = Expression<String>("id")
let title = Expression<String?>("title")
let date = Expression<String>("date")
let isSolved = Expression<Int>("isSolved")

/// create table. if not exists
try db.run(claimTable.create(ifNotExists: true) {
    t in t.column(id, primaryKey: true)
    t.column(title)
    t.column(date)
    t.column(isSolved)
})

/// Post Add Request
router.post("ClaimService/add") {
    request, response, next in
    
    print("Receive Post Request \(Date())")
    
    // try to read from request
    var claim: Claim!
    do {
        claim = try request.read(as: Claim.self)
    } catch {
        response.send("Error claim format.")
        return
    }
    
    // check the format of date
    if (!NSPredicate(format: "SELF MATCHES %@", "^\\d{4} \\d{2}-\\d{2}$").evaluate(with: claim.date)) {
        response.send("Error date format.")
        return
    }
    
    // perform insert.
    do {
        let rowid = try db.run(claimTable.insert(id <- UUID().uuidString, title <- claim.title, date <- claim.date, isSolved <- 0))
        response.send("inserted id: \(rowid)")
    } catch {
        response.send("insertion failed: \(error)")
    }
}


/// Get Request
router.get("ClaimService/getAll") {
    request, response, next in
    print("Receive Get Request \(Date())")
    
    // select from db
    let resp = try db.prepare(claimTable).map({ (row) -> Claim in
        // use map to convert db schema to Claim object
        let isS = row[isSolved] == 0 ? false : true
        let item = Claim(id: UUID(uuidString: row[id])!,title: row[title]!,date: row[date], isSolved: isS)
        return item
    })
    // response
    response.send(resp)
}

// launch method
public func run() {
    // run at 8080. replace if conflict
    Kitura.addHTTPServer(onPort: 8080, with: router)
    Kitura.run()
}


run()
