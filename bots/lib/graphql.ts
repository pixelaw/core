import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core';
import fetch from 'node-fetch'; // Import node-fetch

// Initialize Apollo Client with your GraphQL server URL
export const createClient = (uri: string) => new ApolloClient({
  link: createHttpLink({ uri , fetch }), // Use node-fetch
  cache: new InMemoryCache(),
});
