# Graph Report - SLDepartures  (2026-11-17)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 22 nodes · 32 edges · 4 communities (3 shown, 1 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- View
- StepRow
- SLDeparturesApp
- ContentView.swift

## God Nodes (most connected - your core abstractions)
1. `StepRow` - 6 edges
2. `.body` - 5 edges
3. `BoardPreview` - 4 edges
4. `ContentView` - 4 edges
5. `RefreshNoteView` - 4 edges
6. `InstructionsView` - 4 edges
7. `SLDeparturesApp` - 4 edges
8. `IntroView` - 4 edges
9. `.body` - 2 edges
10. `.body` - 2 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `ContentView`  [INFERRED]
  SLDeparturesApp.swift → ContentView.swift

## Import Cycles
- None detected.

## Communities (4 total, 1 thin omitted)

### Community 0 - "View"
Cohesion: 0.38
Nodes (6): BoardPreview, .body, ContentView, .body, RefreshNoteView, .body

### Community 1 - "StepRow"
Cohesion: 0.33
Nodes (4): InstructionsView, .body, StepRow, .body

### Community 3 - "ContentView.swift"
Cohesion: 0.50
Nodes (3): IntroView, .body, SwiftUI

## Knowledge Gaps
- **4 isolated node(s):** `.body`, `.body`, `.body`, `.body`
  These have ≤1 connection - possible missing edges. (Counts symbols only; 8 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `StepRow` connect `StepRow` to `View`, `ContentView.swift`?**
  _High betweenness centrality (0.305) - this node is a cross-community bridge._
- **What connects `.body`, `.body`, `.body` to the rest of the system?**
  _4 weakly-connected nodes found - possible missing edges._
- **Why does `ContentView` connect `View` to `SLDeparturesApp`, `ContentView.swift`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._