---
title: PathUtils
sidebar_position: 2
---

This API provides some convenient methods to better handle icloud related paths

## Import

```js
import { PathUtils } from 'react-native-cloud-store'
```
## API

### `subPath`
```ts
function subPath(
    from: string,
    to: string
): string

subPath('a', 'a/b') // return  '/b'
```

### `join`
```ts
function join(
  ...segments: string[]
): string

join('a', 'b/c', '/d/e') // return  '/a/b/c/d/e'
```

### `iCloudRemoveDotExt`
```ts
function iCloudRemoveDotExt(
  path: string
): string

iCloudRemoveDotExt('/a/.sth.icloud') // return '/a/sth'
```

### `ext`
```ts
function ext(
  path: string
): string

ext('/a/sth.txt') // return 'txt'
```

