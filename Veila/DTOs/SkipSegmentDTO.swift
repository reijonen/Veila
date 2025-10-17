struct SkipSegmentDTO: Codable {
	let category: String
	let actionType: String
	let segment: [Double]
	let UUID: String
	let videoDuration: Double
	let locked: Int
	let votes: Int
	let description: String
}
