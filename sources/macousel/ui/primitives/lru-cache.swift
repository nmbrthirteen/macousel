struct LRUCache<Key: Hashable, Value> {
  private let limit: Int
  private var values: [Key: Value] = [:]
  private var recency: [Key] = []

  init(limit: Int) {
    self.limit = limit
  }

  mutating func value(for key: Key, make: () -> Value) -> Value {
    if let hit = values[key] {
      recency.removeAll { $0 == key }
      recency.append(key)
      return hit
    }
    let value = make()
    values[key] = value
    recency.append(key)
    if recency.count > limit { values[recency.removeFirst()] = nil }
    return value
  }
}
