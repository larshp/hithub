export function createGitAdmission(limit) {
  const maximum = Number.isInteger(limit) && limit > 0 ? limit : 4;
  let active = 0;
  return {
    acquire() {
      if (active >= maximum) return false;
      active += 1;
      return true;
    },
    release() {
      if (active > 0) active -= 1;
    },
    active() {
      return active;
    },
    limit: maximum,
  };
}
