import Foundation
import Testing

@testable import Macousel

struct LineStreamTests {
  @Test func aChunkSplitsIntoItsCompleteLines() {
    var buffer = Data()

    let lines = LineStream.split(appending: Data("one\ntwo\n".utf8), to: &buffer)

    #expect(lines == ["one", "two"])
    #expect(buffer.isEmpty)
  }

  @Test func aLineCutAcrossChunksArrivesWhole() {
    var buffer = Data()

    let first = LineStream.split(appending: Data("{\"id\":".utf8), to: &buffer)
    let second = LineStream.split(appending: Data("1}\nrest".utf8), to: &buffer)

    #expect(first.isEmpty)
    #expect(second == ["{\"id\":1}"])
    #expect(buffer == Data("rest".utf8))
  }

  @Test func theStreamEndsWhenTheWriterCloses() async {
    let pipe = Pipe()
    pipe.fileHandleForWriting.write(Data("a\nb\n".utf8))
    try? pipe.fileHandleForWriting.close()

    var received: [String] = []
    for await line in LineStream.lines(of: pipe.fileHandleForReading) { received.append(line) }

    #expect(received == ["a", "b"])
  }
}
