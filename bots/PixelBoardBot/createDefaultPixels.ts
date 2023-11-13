import { Pixel } from './types' // Importing the Pixel type
import { DEFAULT_COLOR } from './constants' // Importing the default color constant

// Function to create a default pixel grid of given height and width
const createDefaultPixels = (gridHeight: number, gridWidth: number) => {
  const defaultPixels: Pixel[] = [] // Initialize an empty array to hold the default pixels

  // Loop through each row in the grid
  for (let rowIndex = 0; rowIndex < gridHeight; rowIndex++) {
    // Loop through each column in the grid
    for (let columnIndex = 0; columnIndex < gridWidth; columnIndex++) {
      // Push a new pixel with default properties into the array
      defaultPixels.push({
        x: columnIndex, // The x-coordinate of the pixel
        y: rowIndex, // The y-coordinate of the pixel
        color: {
          ...DEFAULT_COLOR,
          a: 1
        }, // The color of the pixel
        text: '' // The text of the pixel
      })
    }
  }

  // Return the array of default pixels
  return defaultPixels
}

// Export the function as the default export of the module
export default createDefaultPixels
