const checkSiteHealth = async (site: string, silent = false) => {
  try {
    const response = await fetch(site);
    return response.status === 200;
  } catch (e) {
    if (!silent) console.error('Failed to check site health due to: ', e);
    return false;
  }
}

export default checkSiteHealth

