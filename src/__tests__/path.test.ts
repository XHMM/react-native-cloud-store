import { PathUtils } from '../path';

describe("PathUtils test", () => {

  it('relative', () => {
    expect(PathUtils.subPath('a', 'a/b')).toBe('/b')
    expect(() => {
      PathUtils.subPath('/a/b/', 'c/d')
    }).toThrow()
  })

  it('join', () => {
    expect(PathUtils.join('a/b', 'c/d')).toBe('/a/b/c/d')
    expect(PathUtils.join('/a/b/', 'c/d')).toBe('/a/b/c/d')
  })

  it('iCloudRemoveDotExt', () => {
    expect(PathUtils.iCloudRemoveDotExt('a/.b.icloud')).toBe('a/b')
  })

  it('ext', () => {
    expect(PathUtils.ext('a/b/data.txt')).toBe('txt')
  })
})
