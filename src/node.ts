export type Node = {
  move?: string
  suffixAnnotation?: string
  nags: number[]
  comment?: string
  metadata: Record<string,string>
  variations: Node[]
}
