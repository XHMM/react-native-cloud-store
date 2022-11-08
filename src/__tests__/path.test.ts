import { PathUtils } from '../path';

describe("PathUtils test", () => {

  it('relative', () => {
    expect(PathUtils.subPath('a', 'a/b')).toBe('/b')
    expect(() => {
      PathUtils.subPath('/a/b/', 'c/d')
    }).toThrow()

    expect(PathUtils.subPath("a/b", "/a/b")).toBe("/");
  })

  it('join', () => {
    expect(PathUtils.join('a/b', 'c/d')).toBe('/a/b/c/d')
    expect(PathUtils.join('/a/b/', 'c/d')).toBe('/a/b/c/d')
  })

  it('iCloudRemoveDotExt', () => {
    expect(
      PathUtils.iCloudRemoveDotExt(".backup.db.icloud")
    ).toBe("backup.db");
    expect(
      PathUtils.iCloudRemoveDotExt(
        "/Documents/backup/.backup.db.icloud"
      )
    ).toBe("/Documents/backup/backup.db");
  })

  it('ext', () => {
    expect(PathUtils.ext('a/b/data.txt')).toBe('txt')
  })
})
