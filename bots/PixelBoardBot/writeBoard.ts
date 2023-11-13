import * as fs from 'fs';
import * as path from 'path';

const writeBoard = (board: Buffer, filePath: string) => {
  // Get the directory path
  const dirPath = path.dirname(filePath);

  // Check if the directory exists
  if (!fs.existsSync(dirPath)) {
    // Create the directory if it doesn't exist
    fs.mkdirSync(dirPath, { recursive: true });
  }

  // Write to the file
  return fs.writeFileSync(filePath, board);
};


export default writeBoard
