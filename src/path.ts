
export class PathUtils {
  static subPath(from: string, to: string): string {
    from = suffixIf(prefixIf(from, "/"), "/");
    to = suffixIf(prefixIf(to, "/"), "/");

    if(!to.startsWith(from)) {
      throw new Error(`${from} not a sub path to ${to}`);
    }
    return prefixIf(rmSuffixIf(to.slice(from.length), "/"), '/');
  }

  static join(...segments: string[]): string {
    return segments.reduce((acc, cur) => {
      return acc + rmSuffixIf(prefixIf(cur, "/"), "/");
    }, "");
  }

  // change ".xx.icloud" to "xx"
  static iCloudRemoveDotExt(path: string) {
    return path.replace(/(.*?)(\.(.*?)\.icloud)$/, "$1$3");
  }

  static ext(path: string) {
    return path.split(".").pop();
  }
}

function prefixIf(path: string, prefix: string) {
  return path.startsWith(prefix) ? path : prefix + path;
}

function suffixIf(path: string, suffix: string) {
  return path.endsWith(suffix) ? path : path + suffix;
}

// function rmPrefixIf(path: string, prefix: string) {
//   return path.startsWith(prefix) ? path.slice(prefix.length) : path;
// }

function rmSuffixIf(path: string, suffix: string) {
  return path.endsWith(suffix) ? path.slice(0, -suffix.length) : path;
}
