// Import required AWS SDK clients and commands for Node.js.
import { S3Client } from "@aws-sdk/client-s3";
import { CheckOptionalClientConfig as __CheckOptionalClientConfig } from '@smithy/types/dist-types/client'
import { S3ClientConfig } from '@aws-sdk/client-s3/dist-types/S3Client'

export const createS3Client = (
  ...[configuration]: __CheckOptionalClientConfig<S3ClientConfig>
) => new S3Client(configuration)



