// Importing required modules and functions
import { createS3Client } from '../lib/aws'
import { PutObjectCommand } from '@aws-sdk/client-s3'
import * as dotenv from 'dotenv'
import getEnv from '../utils/getEnv'

// Loading environment variables
dotenv.config()

// Checking if required environment variables are present
if (!process.env.AWS_REGION) throw new Error('Missing REQUIRED VARIABLE: AWS_REGION')
if (!process.env.AWS_ACCESS_KEY_ID) throw new Error('Missing REQUIRED VARIABLE: AWS_ACCESS_KEY_ID')
if (!process.env.AWS_SECRET_ACCESS_KEY) throw new Error('Missing REQUIRED VARIABLE: AWS_SECRET_ACCESS_KEY')

// Configuring S3 client with region and credentials
const s3ClientConfig = {
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId : process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  }
}

// Configuring the bucket details
const s3BucketConfig = {
  Bucket: getEnv('S3_BUCKET','pixelaw'),
  Key: getEnv('S3_KEY','pixel-state.png')
}

// Creating an S3 client
const s3Client = createS3Client(s3ClientConfig)

// Function to upload board to S3
const uploadBoard = async (board: Buffer) => {
  // Create an object and upload it to the Amazon S3 bucket.
  try {
    const uploadResults = await s3Client.send(
      new PutObjectCommand({ ...s3BucketConfig, Body: board }));
    console.info(
      "Successfully created " +
      s3BucketConfig.Key +
      " and uploaded it to " +
      s3BucketConfig.Bucket +
      "/" +
      s3BucketConfig.Key
    );
    return uploadResults
  } catch (err) {
    throw new Error("Could not upload the board", err)
  }
}

// Exporting the uploadBoard function
export default uploadBoard
