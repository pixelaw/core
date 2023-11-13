function hexToRGB(hex: string): {r: number, g: number, b: number} {
    let sanitizedHex = hex.startsWith('#') ? hex.slice(1) : hex;
    return {
        r: parseInt(sanitizedHex.slice(0, 2), 16),
        g: parseInt(sanitizedHex.slice(2, 4), 16),
        b: parseInt(sanitizedHex.slice(4, 6), 16)
    };
}

export default hexToRGB
