// unify path format
export function u(path: string): string {
  let prefix = "file://"
  if(path.startsWith(prefix)) {
    path = path.slice(prefix.length)
  }
  return path
}
