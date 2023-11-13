import { GraphQLClient } from 'graphql-request';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { GraphQLClientRequestHeaders } from 'graphql-request/build/cjs/types';
import { print } from 'graphql'
import gql from 'graphql-tag';
export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
export type MakeEmpty<T extends { [key: string]: unknown }, K extends keyof T> = { [_ in K]?: never };
export type Incremental<T> = T | { [P in keyof T]?: P extends ' $fragmentName' | '__typename' ? T[P] : never };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: { input: string; output: string; }
  String: { input: string; output: string; }
  Boolean: { input: boolean; output: boolean; }
  Int: { input: number; output: number; }
  Float: { input: number; output: number; }
  ContractAddress: { input: any; output: any; }
  Cursor: { input: any; output: any; }
  DateTime: { input: any; output: any; }
  Enum: { input: any; output: any; }
  bool: { input: any; output: any; }
  felt252: { input: any; output: any; }
  u8: { input: any; output: any; }
  u32: { input: any; output: any; }
  u64: { input: any; output: any; }
};

export type Alert = {
  __typename?: 'Alert';
  alert?: Maybe<Scalars['felt252']['output']>;
  entity?: Maybe<World__Entity>;
  x?: Maybe<Scalars['u64']['output']>;
  y?: Maybe<Scalars['u64']['output']>;
};

export type AlertConnection = {
  __typename?: 'AlertConnection';
  edges?: Maybe<Array<Maybe<AlertEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type AlertEdge = {
  __typename?: 'AlertEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Alert>;
};

export type AlertOrder = {
  direction: OrderDirection;
  field: AlertOrderField;
};

export enum AlertOrderField {
  Alert = 'ALERT',
  X = 'X',
  Y = 'Y'
}

export type AlertWhereInput = {
  alert?: InputMaybe<Scalars['felt252']['input']>;
  alertEQ?: InputMaybe<Scalars['felt252']['input']>;
  alertGT?: InputMaybe<Scalars['felt252']['input']>;
  alertGTE?: InputMaybe<Scalars['felt252']['input']>;
  alertLT?: InputMaybe<Scalars['felt252']['input']>;
  alertLTE?: InputMaybe<Scalars['felt252']['input']>;
  alertNEQ?: InputMaybe<Scalars['felt252']['input']>;
  x?: InputMaybe<Scalars['u64']['input']>;
  xEQ?: InputMaybe<Scalars['u64']['input']>;
  xGT?: InputMaybe<Scalars['u64']['input']>;
  xGTE?: InputMaybe<Scalars['u64']['input']>;
  xLT?: InputMaybe<Scalars['u64']['input']>;
  xLTE?: InputMaybe<Scalars['u64']['input']>;
  xNEQ?: InputMaybe<Scalars['u64']['input']>;
  y?: InputMaybe<Scalars['u64']['input']>;
  yEQ?: InputMaybe<Scalars['u64']['input']>;
  yGT?: InputMaybe<Scalars['u64']['input']>;
  yGTE?: InputMaybe<Scalars['u64']['input']>;
  yLT?: InputMaybe<Scalars['u64']['input']>;
  yLTE?: InputMaybe<Scalars['u64']['input']>;
  yNEQ?: InputMaybe<Scalars['u64']['input']>;
};

export type App = {
  __typename?: 'App';
  action?: Maybe<Scalars['felt252']['output']>;
  entity?: Maybe<World__Entity>;
  name?: Maybe<Scalars['felt252']['output']>;
  system?: Maybe<Scalars['ContractAddress']['output']>;
};

export type AppConnection = {
  __typename?: 'AppConnection';
  edges?: Maybe<Array<Maybe<AppEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type AppEdge = {
  __typename?: 'AppEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<App>;
};

export type AppName = {
  __typename?: 'AppName';
  entity?: Maybe<World__Entity>;
  name?: Maybe<Scalars['felt252']['output']>;
  system?: Maybe<Scalars['ContractAddress']['output']>;
};

export type AppNameConnection = {
  __typename?: 'AppNameConnection';
  edges?: Maybe<Array<Maybe<AppNameEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type AppNameEdge = {
  __typename?: 'AppNameEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<AppName>;
};

export type AppNameOrder = {
  direction: OrderDirection;
  field: AppNameOrderField;
};

export enum AppNameOrderField {
  Name = 'NAME',
  System = 'SYSTEM'
}

export type AppNameWhereInput = {
  name?: InputMaybe<Scalars['felt252']['input']>;
  nameEQ?: InputMaybe<Scalars['felt252']['input']>;
  nameGT?: InputMaybe<Scalars['felt252']['input']>;
  nameGTE?: InputMaybe<Scalars['felt252']['input']>;
  nameLT?: InputMaybe<Scalars['felt252']['input']>;
  nameLTE?: InputMaybe<Scalars['felt252']['input']>;
  nameNEQ?: InputMaybe<Scalars['felt252']['input']>;
  system?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type AppOrder = {
  direction: OrderDirection;
  field: AppOrderField;
};

export enum AppOrderField {
  Action = 'ACTION',
  Name = 'NAME',
  System = 'SYSTEM'
}

export type AppUser = {
  __typename?: 'AppUser';
  action?: Maybe<Scalars['felt252']['output']>;
  entity?: Maybe<World__Entity>;
  player?: Maybe<Scalars['ContractAddress']['output']>;
  system?: Maybe<Scalars['ContractAddress']['output']>;
};

export type AppUserConnection = {
  __typename?: 'AppUserConnection';
  edges?: Maybe<Array<Maybe<AppUserEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type AppUserEdge = {
  __typename?: 'AppUserEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<AppUser>;
};

export type AppUserOrder = {
  direction: OrderDirection;
  field: AppUserOrderField;
};

export enum AppUserOrderField {
  Action = 'ACTION',
  Player = 'PLAYER',
  System = 'SYSTEM'
}

export type AppUserWhereInput = {
  action?: InputMaybe<Scalars['felt252']['input']>;
  actionEQ?: InputMaybe<Scalars['felt252']['input']>;
  actionGT?: InputMaybe<Scalars['felt252']['input']>;
  actionGTE?: InputMaybe<Scalars['felt252']['input']>;
  actionLT?: InputMaybe<Scalars['felt252']['input']>;
  actionLTE?: InputMaybe<Scalars['felt252']['input']>;
  actionNEQ?: InputMaybe<Scalars['felt252']['input']>;
  player?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  system?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type AppWhereInput = {
  action?: InputMaybe<Scalars['felt252']['input']>;
  actionEQ?: InputMaybe<Scalars['felt252']['input']>;
  actionGT?: InputMaybe<Scalars['felt252']['input']>;
  actionGTE?: InputMaybe<Scalars['felt252']['input']>;
  actionLT?: InputMaybe<Scalars['felt252']['input']>;
  actionLTE?: InputMaybe<Scalars['felt252']['input']>;
  actionNEQ?: InputMaybe<Scalars['felt252']['input']>;
  name?: InputMaybe<Scalars['felt252']['input']>;
  nameEQ?: InputMaybe<Scalars['felt252']['input']>;
  nameGT?: InputMaybe<Scalars['felt252']['input']>;
  nameGTE?: InputMaybe<Scalars['felt252']['input']>;
  nameLT?: InputMaybe<Scalars['felt252']['input']>;
  nameLTE?: InputMaybe<Scalars['felt252']['input']>;
  nameNEQ?: InputMaybe<Scalars['felt252']['input']>;
  system?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type CoreActionsAddress = {
  __typename?: 'CoreActionsAddress';
  entity?: Maybe<World__Entity>;
  key?: Maybe<Scalars['felt252']['output']>;
  value?: Maybe<Scalars['ContractAddress']['output']>;
};

export type CoreActionsAddressConnection = {
  __typename?: 'CoreActionsAddressConnection';
  edges?: Maybe<Array<Maybe<CoreActionsAddressEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type CoreActionsAddressEdge = {
  __typename?: 'CoreActionsAddressEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<CoreActionsAddress>;
};

export type CoreActionsAddressOrder = {
  direction: OrderDirection;
  field: CoreActionsAddressOrderField;
};

export enum CoreActionsAddressOrderField {
  Key = 'KEY',
  Value = 'VALUE'
}

export type CoreActionsAddressWhereInput = {
  key?: InputMaybe<Scalars['felt252']['input']>;
  keyEQ?: InputMaybe<Scalars['felt252']['input']>;
  keyGT?: InputMaybe<Scalars['felt252']['input']>;
  keyGTE?: InputMaybe<Scalars['felt252']['input']>;
  keyLT?: InputMaybe<Scalars['felt252']['input']>;
  keyLTE?: InputMaybe<Scalars['felt252']['input']>;
  keyNEQ?: InputMaybe<Scalars['felt252']['input']>;
  value?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  valueNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type Game = {
  __typename?: 'Game';
  entity?: Maybe<World__Entity>;
  id?: Maybe<Scalars['u32']['output']>;
  player1?: Maybe<Scalars['ContractAddress']['output']>;
  player1_commit?: Maybe<Scalars['felt252']['output']>;
  player1_move?: Maybe<Scalars['Enum']['output']>;
  player2?: Maybe<Scalars['ContractAddress']['output']>;
  player2_move?: Maybe<Scalars['Enum']['output']>;
  started_timestamp?: Maybe<Scalars['u64']['output']>;
  state?: Maybe<Scalars['Enum']['output']>;
  x?: Maybe<Scalars['u64']['output']>;
  y?: Maybe<Scalars['u64']['output']>;
};

export type GameConnection = {
  __typename?: 'GameConnection';
  edges?: Maybe<Array<Maybe<GameEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type GameEdge = {
  __typename?: 'GameEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Game>;
};

export type GameOrder = {
  direction: OrderDirection;
  field: GameOrderField;
};

export enum GameOrderField {
  Id = 'ID',
  Player1 = 'PLAYER1',
  Player1Commit = 'PLAYER1_COMMIT',
  Player1Move = 'PLAYER1_MOVE',
  Player2 = 'PLAYER2',
  Player2Move = 'PLAYER2_MOVE',
  StartedTimestamp = 'STARTED_TIMESTAMP',
  State = 'STATE',
  X = 'X',
  Y = 'Y'
}

export type GameWhereInput = {
  id?: InputMaybe<Scalars['u32']['input']>;
  idEQ?: InputMaybe<Scalars['u32']['input']>;
  idGT?: InputMaybe<Scalars['u32']['input']>;
  idGTE?: InputMaybe<Scalars['u32']['input']>;
  idLT?: InputMaybe<Scalars['u32']['input']>;
  idLTE?: InputMaybe<Scalars['u32']['input']>;
  idNEQ?: InputMaybe<Scalars['u32']['input']>;
  player1?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1EQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1GT?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1GTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1LT?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1LTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1NEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  player1_commit?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitEQ?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitGT?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitGTE?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitLT?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitLTE?: InputMaybe<Scalars['felt252']['input']>;
  player1_commitNEQ?: InputMaybe<Scalars['felt252']['input']>;
  player1_move?: InputMaybe<Scalars['Enum']['input']>;
  player2?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2EQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2GT?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2GTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2LT?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2LTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2NEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  player2_move?: InputMaybe<Scalars['Enum']['input']>;
  started_timestamp?: InputMaybe<Scalars['u64']['input']>;
  started_timestampEQ?: InputMaybe<Scalars['u64']['input']>;
  started_timestampGT?: InputMaybe<Scalars['u64']['input']>;
  started_timestampGTE?: InputMaybe<Scalars['u64']['input']>;
  started_timestampLT?: InputMaybe<Scalars['u64']['input']>;
  started_timestampLTE?: InputMaybe<Scalars['u64']['input']>;
  started_timestampNEQ?: InputMaybe<Scalars['u64']['input']>;
  state?: InputMaybe<Scalars['Enum']['input']>;
  x?: InputMaybe<Scalars['u64']['input']>;
  xEQ?: InputMaybe<Scalars['u64']['input']>;
  xGT?: InputMaybe<Scalars['u64']['input']>;
  xGTE?: InputMaybe<Scalars['u64']['input']>;
  xLT?: InputMaybe<Scalars['u64']['input']>;
  xLTE?: InputMaybe<Scalars['u64']['input']>;
  xNEQ?: InputMaybe<Scalars['u64']['input']>;
  y?: InputMaybe<Scalars['u64']['input']>;
  yEQ?: InputMaybe<Scalars['u64']['input']>;
  yGT?: InputMaybe<Scalars['u64']['input']>;
  yGTE?: InputMaybe<Scalars['u64']['input']>;
  yLT?: InputMaybe<Scalars['u64']['input']>;
  yLTE?: InputMaybe<Scalars['u64']['input']>;
  yNEQ?: InputMaybe<Scalars['u64']['input']>;
};

export type LastAttempt = {
  __typename?: 'LastAttempt';
  entity?: Maybe<World__Entity>;
  player?: Maybe<Scalars['ContractAddress']['output']>;
  timestamp?: Maybe<Scalars['u64']['output']>;
};

export type LastAttemptConnection = {
  __typename?: 'LastAttemptConnection';
  edges?: Maybe<Array<Maybe<LastAttemptEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type LastAttemptEdge = {
  __typename?: 'LastAttemptEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<LastAttempt>;
};

export type LastAttemptOrder = {
  direction: OrderDirection;
  field: LastAttemptOrderField;
};

export enum LastAttemptOrderField {
  Player = 'PLAYER',
  Timestamp = 'TIMESTAMP'
}

export type LastAttemptWhereInput = {
  player?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  playerNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  timestamp?: InputMaybe<Scalars['u64']['input']>;
  timestampEQ?: InputMaybe<Scalars['u64']['input']>;
  timestampGT?: InputMaybe<Scalars['u64']['input']>;
  timestampGTE?: InputMaybe<Scalars['u64']['input']>;
  timestampLT?: InputMaybe<Scalars['u64']['input']>;
  timestampLTE?: InputMaybe<Scalars['u64']['input']>;
  timestampNEQ?: InputMaybe<Scalars['u64']['input']>;
};

export type ModelUnion = Alert | App | AppName | AppUser | CoreActionsAddress | Game | LastAttempt | Permissions | Pixel | Player | QueueItem | Snake | SnakeSegment;

export enum OrderDirection {
  Asc = 'ASC',
  Desc = 'DESC'
}

export type Permissions = {
  __typename?: 'Permissions';
  allowed_app?: Maybe<Scalars['ContractAddress']['output']>;
  allowing_app?: Maybe<Scalars['ContractAddress']['output']>;
  entity?: Maybe<World__Entity>;
  permission?: Maybe<Permissions_Permission>;
};

export type PermissionsConnection = {
  __typename?: 'PermissionsConnection';
  edges?: Maybe<Array<Maybe<PermissionsEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type PermissionsEdge = {
  __typename?: 'PermissionsEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Permissions>;
};

export type PermissionsOrder = {
  direction: OrderDirection;
  field: PermissionsOrderField;
};

export enum PermissionsOrderField {
  AllowedApp = 'ALLOWED_APP',
  AllowingApp = 'ALLOWING_APP',
  Permission = 'PERMISSION'
}

export type PermissionsWhereInput = {
  allowed_app?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowed_appNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_app?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  allowing_appNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type Permissions_Permission = {
  __typename?: 'Permissions_Permission';
  action?: Maybe<Scalars['bool']['output']>;
  alert?: Maybe<Scalars['bool']['output']>;
  app?: Maybe<Scalars['bool']['output']>;
  color?: Maybe<Scalars['bool']['output']>;
  owner?: Maybe<Scalars['bool']['output']>;
  text?: Maybe<Scalars['bool']['output']>;
  timestamp?: Maybe<Scalars['bool']['output']>;
};

export type Pixel = {
  __typename?: 'Pixel';
  action?: Maybe<Scalars['felt252']['output']>;
  alert?: Maybe<Scalars['felt252']['output']>;
  app?: Maybe<Scalars['ContractAddress']['output']>;
  color?: Maybe<Scalars['u32']['output']>;
  created_at?: Maybe<Scalars['u64']['output']>;
  entity?: Maybe<World__Entity>;
  owner?: Maybe<Scalars['ContractAddress']['output']>;
  text?: Maybe<Scalars['felt252']['output']>;
  timestamp?: Maybe<Scalars['u64']['output']>;
  updated_at?: Maybe<Scalars['u64']['output']>;
  x?: Maybe<Scalars['u64']['output']>;
  y?: Maybe<Scalars['u64']['output']>;
};

export type PixelConnection = {
  __typename?: 'PixelConnection';
  edges?: Maybe<Array<Maybe<PixelEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type PixelEdge = {
  __typename?: 'PixelEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Pixel>;
};

export type PixelOrder = {
  direction: OrderDirection;
  field: PixelOrderField;
};

export enum PixelOrderField {
  Action = 'ACTION',
  Alert = 'ALERT',
  App = 'APP',
  Color = 'COLOR',
  CreatedAt = 'CREATED_AT',
  Owner = 'OWNER',
  Text = 'TEXT',
  Timestamp = 'TIMESTAMP',
  UpdatedAt = 'UPDATED_AT',
  X = 'X',
  Y = 'Y'
}

export type PixelWhereInput = {
  action?: InputMaybe<Scalars['felt252']['input']>;
  actionEQ?: InputMaybe<Scalars['felt252']['input']>;
  actionGT?: InputMaybe<Scalars['felt252']['input']>;
  actionGTE?: InputMaybe<Scalars['felt252']['input']>;
  actionLT?: InputMaybe<Scalars['felt252']['input']>;
  actionLTE?: InputMaybe<Scalars['felt252']['input']>;
  actionNEQ?: InputMaybe<Scalars['felt252']['input']>;
  alert?: InputMaybe<Scalars['felt252']['input']>;
  alertEQ?: InputMaybe<Scalars['felt252']['input']>;
  alertGT?: InputMaybe<Scalars['felt252']['input']>;
  alertGTE?: InputMaybe<Scalars['felt252']['input']>;
  alertLT?: InputMaybe<Scalars['felt252']['input']>;
  alertLTE?: InputMaybe<Scalars['felt252']['input']>;
  alertNEQ?: InputMaybe<Scalars['felt252']['input']>;
  app?: InputMaybe<Scalars['ContractAddress']['input']>;
  appEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  appGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  appGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  appLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  appLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  appNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  color?: InputMaybe<Scalars['u32']['input']>;
  colorEQ?: InputMaybe<Scalars['u32']['input']>;
  colorGT?: InputMaybe<Scalars['u32']['input']>;
  colorGTE?: InputMaybe<Scalars['u32']['input']>;
  colorLT?: InputMaybe<Scalars['u32']['input']>;
  colorLTE?: InputMaybe<Scalars['u32']['input']>;
  colorNEQ?: InputMaybe<Scalars['u32']['input']>;
  created_at?: InputMaybe<Scalars['u64']['input']>;
  created_atEQ?: InputMaybe<Scalars['u64']['input']>;
  created_atGT?: InputMaybe<Scalars['u64']['input']>;
  created_atGTE?: InputMaybe<Scalars['u64']['input']>;
  created_atLT?: InputMaybe<Scalars['u64']['input']>;
  created_atLTE?: InputMaybe<Scalars['u64']['input']>;
  created_atNEQ?: InputMaybe<Scalars['u64']['input']>;
  owner?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  text?: InputMaybe<Scalars['felt252']['input']>;
  textEQ?: InputMaybe<Scalars['felt252']['input']>;
  textGT?: InputMaybe<Scalars['felt252']['input']>;
  textGTE?: InputMaybe<Scalars['felt252']['input']>;
  textLT?: InputMaybe<Scalars['felt252']['input']>;
  textLTE?: InputMaybe<Scalars['felt252']['input']>;
  textNEQ?: InputMaybe<Scalars['felt252']['input']>;
  timestamp?: InputMaybe<Scalars['u64']['input']>;
  timestampEQ?: InputMaybe<Scalars['u64']['input']>;
  timestampGT?: InputMaybe<Scalars['u64']['input']>;
  timestampGTE?: InputMaybe<Scalars['u64']['input']>;
  timestampLT?: InputMaybe<Scalars['u64']['input']>;
  timestampLTE?: InputMaybe<Scalars['u64']['input']>;
  timestampNEQ?: InputMaybe<Scalars['u64']['input']>;
  updated_at?: InputMaybe<Scalars['u64']['input']>;
  updated_atEQ?: InputMaybe<Scalars['u64']['input']>;
  updated_atGT?: InputMaybe<Scalars['u64']['input']>;
  updated_atGTE?: InputMaybe<Scalars['u64']['input']>;
  updated_atLT?: InputMaybe<Scalars['u64']['input']>;
  updated_atLTE?: InputMaybe<Scalars['u64']['input']>;
  updated_atNEQ?: InputMaybe<Scalars['u64']['input']>;
  x?: InputMaybe<Scalars['u64']['input']>;
  xEQ?: InputMaybe<Scalars['u64']['input']>;
  xGT?: InputMaybe<Scalars['u64']['input']>;
  xGTE?: InputMaybe<Scalars['u64']['input']>;
  xLT?: InputMaybe<Scalars['u64']['input']>;
  xLTE?: InputMaybe<Scalars['u64']['input']>;
  xNEQ?: InputMaybe<Scalars['u64']['input']>;
  y?: InputMaybe<Scalars['u64']['input']>;
  yEQ?: InputMaybe<Scalars['u64']['input']>;
  yGT?: InputMaybe<Scalars['u64']['input']>;
  yGTE?: InputMaybe<Scalars['u64']['input']>;
  yLT?: InputMaybe<Scalars['u64']['input']>;
  yLTE?: InputMaybe<Scalars['u64']['input']>;
  yNEQ?: InputMaybe<Scalars['u64']['input']>;
};

export type Player = {
  __typename?: 'Player';
  entity?: Maybe<World__Entity>;
  player_id?: Maybe<Scalars['felt252']['output']>;
  wins?: Maybe<Scalars['u32']['output']>;
};

export type PlayerConnection = {
  __typename?: 'PlayerConnection';
  edges?: Maybe<Array<Maybe<PlayerEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type PlayerEdge = {
  __typename?: 'PlayerEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Player>;
};

export type PlayerOrder = {
  direction: OrderDirection;
  field: PlayerOrderField;
};

export enum PlayerOrderField {
  PlayerId = 'PLAYER_ID',
  Wins = 'WINS'
}

export type PlayerWhereInput = {
  player_id?: InputMaybe<Scalars['felt252']['input']>;
  player_idEQ?: InputMaybe<Scalars['felt252']['input']>;
  player_idGT?: InputMaybe<Scalars['felt252']['input']>;
  player_idGTE?: InputMaybe<Scalars['felt252']['input']>;
  player_idLT?: InputMaybe<Scalars['felt252']['input']>;
  player_idLTE?: InputMaybe<Scalars['felt252']['input']>;
  player_idNEQ?: InputMaybe<Scalars['felt252']['input']>;
  wins?: InputMaybe<Scalars['u32']['input']>;
  winsEQ?: InputMaybe<Scalars['u32']['input']>;
  winsGT?: InputMaybe<Scalars['u32']['input']>;
  winsGTE?: InputMaybe<Scalars['u32']['input']>;
  winsLT?: InputMaybe<Scalars['u32']['input']>;
  winsLTE?: InputMaybe<Scalars['u32']['input']>;
  winsNEQ?: InputMaybe<Scalars['u32']['input']>;
};

export type QueueItem = {
  __typename?: 'QueueItem';
  entity?: Maybe<World__Entity>;
  id?: Maybe<Scalars['felt252']['output']>;
  valid?: Maybe<Scalars['bool']['output']>;
};

export type QueueItemConnection = {
  __typename?: 'QueueItemConnection';
  edges?: Maybe<Array<Maybe<QueueItemEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type QueueItemEdge = {
  __typename?: 'QueueItemEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<QueueItem>;
};

export type QueueItemOrder = {
  direction: OrderDirection;
  field: QueueItemOrderField;
};

export enum QueueItemOrderField {
  Id = 'ID',
  Valid = 'VALID'
}

export type QueueItemWhereInput = {
  id?: InputMaybe<Scalars['felt252']['input']>;
  idEQ?: InputMaybe<Scalars['felt252']['input']>;
  idGT?: InputMaybe<Scalars['felt252']['input']>;
  idGTE?: InputMaybe<Scalars['felt252']['input']>;
  idLT?: InputMaybe<Scalars['felt252']['input']>;
  idLTE?: InputMaybe<Scalars['felt252']['input']>;
  idNEQ?: InputMaybe<Scalars['felt252']['input']>;
  valid?: InputMaybe<Scalars['bool']['input']>;
  validEQ?: InputMaybe<Scalars['bool']['input']>;
  validGT?: InputMaybe<Scalars['bool']['input']>;
  validGTE?: InputMaybe<Scalars['bool']['input']>;
  validLT?: InputMaybe<Scalars['bool']['input']>;
  validLTE?: InputMaybe<Scalars['bool']['input']>;
  validNEQ?: InputMaybe<Scalars['bool']['input']>;
};

export type Snake = {
  __typename?: 'Snake';
  color?: Maybe<Scalars['u32']['output']>;
  direction?: Maybe<Scalars['Enum']['output']>;
  entity?: Maybe<World__Entity>;
  first_segment_id?: Maybe<Scalars['u32']['output']>;
  is_dying?: Maybe<Scalars['bool']['output']>;
  last_segment_id?: Maybe<Scalars['u32']['output']>;
  length?: Maybe<Scalars['u8']['output']>;
  owner?: Maybe<Scalars['ContractAddress']['output']>;
  text?: Maybe<Scalars['felt252']['output']>;
};

export type SnakeConnection = {
  __typename?: 'SnakeConnection';
  edges?: Maybe<Array<Maybe<SnakeEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type SnakeEdge = {
  __typename?: 'SnakeEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Snake>;
};

export type SnakeOrder = {
  direction: OrderDirection;
  field: SnakeOrderField;
};

export enum SnakeOrderField {
  Color = 'COLOR',
  Direction = 'DIRECTION',
  FirstSegmentId = 'FIRST_SEGMENT_ID',
  IsDying = 'IS_DYING',
  LastSegmentId = 'LAST_SEGMENT_ID',
  Length = 'LENGTH',
  Owner = 'OWNER',
  Text = 'TEXT'
}

export type SnakeSegment = {
  __typename?: 'SnakeSegment';
  entity?: Maybe<World__Entity>;
  id?: Maybe<Scalars['u32']['output']>;
  next_id?: Maybe<Scalars['u32']['output']>;
  pixel_original_color?: Maybe<Scalars['u32']['output']>;
  pixel_original_text?: Maybe<Scalars['felt252']['output']>;
  previous_id?: Maybe<Scalars['u32']['output']>;
  x?: Maybe<Scalars['u64']['output']>;
  y?: Maybe<Scalars['u64']['output']>;
};

export type SnakeSegmentConnection = {
  __typename?: 'SnakeSegmentConnection';
  edges?: Maybe<Array<Maybe<SnakeSegmentEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type SnakeSegmentEdge = {
  __typename?: 'SnakeSegmentEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<SnakeSegment>;
};

export type SnakeSegmentOrder = {
  direction: OrderDirection;
  field: SnakeSegmentOrderField;
};

export enum SnakeSegmentOrderField {
  Id = 'ID',
  NextId = 'NEXT_ID',
  PixelOriginalColor = 'PIXEL_ORIGINAL_COLOR',
  PixelOriginalText = 'PIXEL_ORIGINAL_TEXT',
  PreviousId = 'PREVIOUS_ID',
  X = 'X',
  Y = 'Y'
}

export type SnakeSegmentWhereInput = {
  id?: InputMaybe<Scalars['u32']['input']>;
  idEQ?: InputMaybe<Scalars['u32']['input']>;
  idGT?: InputMaybe<Scalars['u32']['input']>;
  idGTE?: InputMaybe<Scalars['u32']['input']>;
  idLT?: InputMaybe<Scalars['u32']['input']>;
  idLTE?: InputMaybe<Scalars['u32']['input']>;
  idNEQ?: InputMaybe<Scalars['u32']['input']>;
  next_id?: InputMaybe<Scalars['u32']['input']>;
  next_idEQ?: InputMaybe<Scalars['u32']['input']>;
  next_idGT?: InputMaybe<Scalars['u32']['input']>;
  next_idGTE?: InputMaybe<Scalars['u32']['input']>;
  next_idLT?: InputMaybe<Scalars['u32']['input']>;
  next_idLTE?: InputMaybe<Scalars['u32']['input']>;
  next_idNEQ?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_color?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorEQ?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorGT?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorGTE?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorLT?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorLTE?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_colorNEQ?: InputMaybe<Scalars['u32']['input']>;
  pixel_original_text?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textEQ?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textGT?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textGTE?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textLT?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textLTE?: InputMaybe<Scalars['felt252']['input']>;
  pixel_original_textNEQ?: InputMaybe<Scalars['felt252']['input']>;
  previous_id?: InputMaybe<Scalars['u32']['input']>;
  previous_idEQ?: InputMaybe<Scalars['u32']['input']>;
  previous_idGT?: InputMaybe<Scalars['u32']['input']>;
  previous_idGTE?: InputMaybe<Scalars['u32']['input']>;
  previous_idLT?: InputMaybe<Scalars['u32']['input']>;
  previous_idLTE?: InputMaybe<Scalars['u32']['input']>;
  previous_idNEQ?: InputMaybe<Scalars['u32']['input']>;
  x?: InputMaybe<Scalars['u64']['input']>;
  xEQ?: InputMaybe<Scalars['u64']['input']>;
  xGT?: InputMaybe<Scalars['u64']['input']>;
  xGTE?: InputMaybe<Scalars['u64']['input']>;
  xLT?: InputMaybe<Scalars['u64']['input']>;
  xLTE?: InputMaybe<Scalars['u64']['input']>;
  xNEQ?: InputMaybe<Scalars['u64']['input']>;
  y?: InputMaybe<Scalars['u64']['input']>;
  yEQ?: InputMaybe<Scalars['u64']['input']>;
  yGT?: InputMaybe<Scalars['u64']['input']>;
  yGTE?: InputMaybe<Scalars['u64']['input']>;
  yLT?: InputMaybe<Scalars['u64']['input']>;
  yLTE?: InputMaybe<Scalars['u64']['input']>;
  yNEQ?: InputMaybe<Scalars['u64']['input']>;
};

export type SnakeWhereInput = {
  color?: InputMaybe<Scalars['u32']['input']>;
  colorEQ?: InputMaybe<Scalars['u32']['input']>;
  colorGT?: InputMaybe<Scalars['u32']['input']>;
  colorGTE?: InputMaybe<Scalars['u32']['input']>;
  colorLT?: InputMaybe<Scalars['u32']['input']>;
  colorLTE?: InputMaybe<Scalars['u32']['input']>;
  colorNEQ?: InputMaybe<Scalars['u32']['input']>;
  direction?: InputMaybe<Scalars['Enum']['input']>;
  first_segment_id?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idEQ?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idGT?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idGTE?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idLT?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idLTE?: InputMaybe<Scalars['u32']['input']>;
  first_segment_idNEQ?: InputMaybe<Scalars['u32']['input']>;
  is_dying?: InputMaybe<Scalars['bool']['input']>;
  is_dyingEQ?: InputMaybe<Scalars['bool']['input']>;
  is_dyingGT?: InputMaybe<Scalars['bool']['input']>;
  is_dyingGTE?: InputMaybe<Scalars['bool']['input']>;
  is_dyingLT?: InputMaybe<Scalars['bool']['input']>;
  is_dyingLTE?: InputMaybe<Scalars['bool']['input']>;
  is_dyingNEQ?: InputMaybe<Scalars['bool']['input']>;
  last_segment_id?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idEQ?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idGT?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idGTE?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idLT?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idLTE?: InputMaybe<Scalars['u32']['input']>;
  last_segment_idNEQ?: InputMaybe<Scalars['u32']['input']>;
  length?: InputMaybe<Scalars['u8']['input']>;
  lengthEQ?: InputMaybe<Scalars['u8']['input']>;
  lengthGT?: InputMaybe<Scalars['u8']['input']>;
  lengthGTE?: InputMaybe<Scalars['u8']['input']>;
  lengthLT?: InputMaybe<Scalars['u8']['input']>;
  lengthLTE?: InputMaybe<Scalars['u8']['input']>;
  lengthNEQ?: InputMaybe<Scalars['u8']['input']>;
  owner?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  ownerNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  text?: InputMaybe<Scalars['felt252']['input']>;
  textEQ?: InputMaybe<Scalars['felt252']['input']>;
  textGT?: InputMaybe<Scalars['felt252']['input']>;
  textGTE?: InputMaybe<Scalars['felt252']['input']>;
  textLT?: InputMaybe<Scalars['felt252']['input']>;
  textLTE?: InputMaybe<Scalars['felt252']['input']>;
  textNEQ?: InputMaybe<Scalars['felt252']['input']>;
};

export type World__Content = {
  __typename?: 'World__Content';
  cover_uri?: Maybe<Scalars['String']['output']>;
  description?: Maybe<Scalars['String']['output']>;
  icon_uri?: Maybe<Scalars['String']['output']>;
  name?: Maybe<Scalars['String']['output']>;
  socials?: Maybe<Array<Maybe<World__Social>>>;
  website?: Maybe<Scalars['String']['output']>;
};

export type World__Entity = {
  __typename?: 'World__Entity';
  created_at?: Maybe<Scalars['DateTime']['output']>;
  event_id?: Maybe<Scalars['String']['output']>;
  id?: Maybe<Scalars['ID']['output']>;
  keys?: Maybe<Array<Maybe<Scalars['String']['output']>>>;
  model_names?: Maybe<Scalars['String']['output']>;
  models?: Maybe<Array<Maybe<ModelUnion>>>;
  updated_at?: Maybe<Scalars['DateTime']['output']>;
};

export type World__EntityConnection = {
  __typename?: 'World__EntityConnection';
  edges?: Maybe<Array<Maybe<World__EntityEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type World__EntityEdge = {
  __typename?: 'World__EntityEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<World__Entity>;
};

export type World__Event = {
  __typename?: 'World__Event';
  created_at?: Maybe<Scalars['DateTime']['output']>;
  data?: Maybe<Array<Maybe<Scalars['String']['output']>>>;
  id?: Maybe<Scalars['ID']['output']>;
  keys?: Maybe<Array<Maybe<Scalars['String']['output']>>>;
  transaction_hash?: Maybe<Scalars['String']['output']>;
};

export type World__EventConnection = {
  __typename?: 'World__EventConnection';
  edges?: Maybe<Array<Maybe<World__EventEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type World__EventEdge = {
  __typename?: 'World__EventEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<World__Event>;
};

export type World__Metadata = {
  __typename?: 'World__Metadata';
  content?: Maybe<World__Content>;
  cover_img?: Maybe<Scalars['String']['output']>;
  created_at?: Maybe<Scalars['DateTime']['output']>;
  icon_img?: Maybe<Scalars['String']['output']>;
  id?: Maybe<Scalars['ID']['output']>;
  updated_at?: Maybe<Scalars['DateTime']['output']>;
  uri?: Maybe<Scalars['String']['output']>;
};

export type World__MetadataConnection = {
  __typename?: 'World__MetadataConnection';
  edges?: Maybe<Array<Maybe<World__MetadataEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type World__MetadataEdge = {
  __typename?: 'World__MetadataEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<World__Metadata>;
};

export type World__Model = {
  __typename?: 'World__Model';
  class_hash?: Maybe<Scalars['felt252']['output']>;
  created_at?: Maybe<Scalars['DateTime']['output']>;
  id?: Maybe<Scalars['ID']['output']>;
  name?: Maybe<Scalars['String']['output']>;
  transaction_hash?: Maybe<Scalars['felt252']['output']>;
};

export type World__ModelConnection = {
  __typename?: 'World__ModelConnection';
  edges?: Maybe<Array<Maybe<World__ModelEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type World__ModelEdge = {
  __typename?: 'World__ModelEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<World__Model>;
};

export type World__Query = {
  __typename?: 'World__Query';
  alertModels?: Maybe<AlertConnection>;
  appModels?: Maybe<AppConnection>;
  appnameModels?: Maybe<AppNameConnection>;
  appuserModels?: Maybe<AppUserConnection>;
  coreactionsaddressModels?: Maybe<CoreActionsAddressConnection>;
  entities?: Maybe<World__EntityConnection>;
  entity: World__Entity;
  events?: Maybe<World__EventConnection>;
  gameModels?: Maybe<GameConnection>;
  lastattemptModels?: Maybe<LastAttemptConnection>;
  metadatas?: Maybe<World__MetadataConnection>;
  model: World__Model;
  models?: Maybe<World__ModelConnection>;
  permissionsModels?: Maybe<PermissionsConnection>;
  pixelModels?: Maybe<PixelConnection>;
  playerModels?: Maybe<PlayerConnection>;
  queueitemModels?: Maybe<QueueItemConnection>;
  snakeModels?: Maybe<SnakeConnection>;
  snakesegmentModels?: Maybe<SnakeSegmentConnection>;
  transaction: World__Transaction;
  transactions?: Maybe<World__TransactionConnection>;
};


export type World__QueryAlertModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<AlertOrder>;
  where?: InputMaybe<AlertWhereInput>;
};


export type World__QueryAppModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<AppOrder>;
  where?: InputMaybe<AppWhereInput>;
};


export type World__QueryAppnameModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<AppNameOrder>;
  where?: InputMaybe<AppNameWhereInput>;
};


export type World__QueryAppuserModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<AppUserOrder>;
  where?: InputMaybe<AppUserWhereInput>;
};


export type World__QueryCoreactionsaddressModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<CoreActionsAddressOrder>;
  where?: InputMaybe<CoreActionsAddressWhereInput>;
};


export type World__QueryEntitiesArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  keys?: InputMaybe<Array<InputMaybe<Scalars['String']['input']>>>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
};


export type World__QueryEntityArgs = {
  id: Scalars['ID']['input'];
};


export type World__QueryEventsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  keys?: InputMaybe<Array<InputMaybe<Scalars['String']['input']>>>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
};


export type World__QueryGameModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<GameOrder>;
  where?: InputMaybe<GameWhereInput>;
};


export type World__QueryLastattemptModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<LastAttemptOrder>;
  where?: InputMaybe<LastAttemptWhereInput>;
};


export type World__QueryMetadatasArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
};


export type World__QueryModelArgs = {
  id: Scalars['ID']['input'];
};


export type World__QueryModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
};


export type World__QueryPermissionsModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<PermissionsOrder>;
  where?: InputMaybe<PermissionsWhereInput>;
};


export type World__QueryPixelModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<PixelOrder>;
  where?: InputMaybe<PixelWhereInput>;
};


export type World__QueryPlayerModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<PlayerOrder>;
  where?: InputMaybe<PlayerWhereInput>;
};


export type World__QueryQueueitemModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<QueueItemOrder>;
  where?: InputMaybe<QueueItemWhereInput>;
};


export type World__QuerySnakeModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<SnakeOrder>;
  where?: InputMaybe<SnakeWhereInput>;
};


export type World__QuerySnakesegmentModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<SnakeSegmentOrder>;
  where?: InputMaybe<SnakeSegmentWhereInput>;
};


export type World__QueryTransactionArgs = {
  id: Scalars['ID']['input'];
};


export type World__QueryTransactionsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
};

export type World__Social = {
  __typename?: 'World__Social';
  name?: Maybe<Scalars['String']['output']>;
  url?: Maybe<Scalars['String']['output']>;
};

export type World__Subscription = {
  __typename?: 'World__Subscription';
  entityUpdated: World__Entity;
  eventEmitted: World__Event;
  modelRegistered: World__Model;
};


export type World__SubscriptionEntityUpdatedArgs = {
  id?: InputMaybe<Scalars['ID']['input']>;
};


export type World__SubscriptionEventEmittedArgs = {
  keys?: InputMaybe<Array<InputMaybe<Scalars['String']['input']>>>;
};


export type World__SubscriptionModelRegisteredArgs = {
  id?: InputMaybe<Scalars['ID']['input']>;
};

export type World__Transaction = {
  __typename?: 'World__Transaction';
  calldata?: Maybe<Array<Maybe<Scalars['felt252']['output']>>>;
  created_at?: Maybe<Scalars['DateTime']['output']>;
  id?: Maybe<Scalars['ID']['output']>;
  max_fee?: Maybe<Scalars['felt252']['output']>;
  nonce?: Maybe<Scalars['felt252']['output']>;
  sender_address?: Maybe<Scalars['felt252']['output']>;
  signature?: Maybe<Array<Maybe<Scalars['felt252']['output']>>>;
  transaction_hash?: Maybe<Scalars['felt252']['output']>;
};

export type World__TransactionConnection = {
  __typename?: 'World__TransactionConnection';
  edges?: Maybe<Array<Maybe<World__TransactionEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type World__TransactionEdge = {
  __typename?: 'World__TransactionEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<World__Transaction>;
};

export type GetEntitiesQueryVariables = Exact<{ [key: string]: never; }>;


export type GetEntitiesQuery = { __typename?: 'World__Query', entities?: { __typename?: 'World__EntityConnection', edges?: Array<{ __typename?: 'World__EntityEdge', node?: { __typename?: 'World__Entity', keys?: Array<string | null> | null, models?: Array<{ __typename: 'Alert', x?: any | null, y?: any | null, alert?: any | null } | { __typename: 'App', name?: any | null, system?: any | null } | { __typename: 'AppName', name?: any | null, system?: any | null } | { __typename?: 'AppUser' } | { __typename: 'CoreActionsAddress', key?: any | null, value?: any | null } | { __typename: 'Game', x?: any | null, y?: any | null, id?: any | null, state?: any | null, player1?: any | null, player2?: any | null, player1_commit?: any | null, player1_move?: any | null, player2_move?: any | null, started_timestamp?: any | null } | { __typename?: 'LastAttempt' } | { __typename: 'Permissions', allowing_app?: any | null, allowed_app?: any | null, permission?: { __typename: 'Permissions_Permission', alert?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | null } | { __typename: 'Pixel', x?: any | null, y?: any | null, created_at?: any | null, updated_at?: any | null, alert?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | { __typename: 'Player', player_id?: any | null, wins?: any | null } | { __typename?: 'QueueItem' } | { __typename: 'Snake', length?: any | null, first_segment_id?: any | null, last_segment_id?: any | null, direction?: any | null, owner?: any | null, color?: any | null, text?: any | null, is_dying?: any | null } | { __typename: 'SnakeSegment', id?: any | null, previous_id?: any | null, next_id?: any | null, x?: any | null, y?: any | null, pixel_original_color?: any | null, pixel_original_text?: any | null } | null> | null } | null } | null> | null } | null };

export type All_Filtered_EntitiesQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
  xMin?: InputMaybe<Scalars['u64']['input']>;
  xMax?: InputMaybe<Scalars['u64']['input']>;
  yMin?: InputMaybe<Scalars['u64']['input']>;
  yMax?: InputMaybe<Scalars['u64']['input']>;
}>;


export type All_Filtered_EntitiesQuery = { __typename?: 'World__Query', pixelModels?: { __typename?: 'PixelConnection', edges?: Array<{ __typename?: 'PixelEdge', node?: { __typename: 'Pixel', x?: any | null, y?: any | null, created_at?: any | null, updated_at?: any | null, alert?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | null } | null> | null } | null };

export type GetNeedsAttentionQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
  address?: InputMaybe<Scalars['ContractAddress']['input']>;
}>;


export type GetNeedsAttentionQuery = { __typename?: 'World__Query', pixelModels?: { __typename?: 'PixelConnection', edges?: Array<{ __typename?: 'PixelEdge', node?: { __typename: 'Pixel', x?: any | null, y?: any | null, created_at?: any | null, updated_at?: any | null, alert?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | null } | null> | null } | null, alertModels?: { __typename?: 'AlertConnection', edges?: Array<{ __typename?: 'AlertEdge', node?: { __typename: 'Alert', x?: any | null, y?: any | null, alert?: any | null } | null } | null> | null } | null };

export type AppsQueryVariables = Exact<{ [key: string]: never; }>;


export type AppsQuery = { __typename?: 'World__Query', appModels?: { __typename?: 'AppConnection', edges?: Array<{ __typename?: 'AppEdge', node?: { __typename: 'App', action?: any | null, name?: any | null, system?: any | null } | null } | null> | null } | null };


export const GetEntitiesDocument = gql`
    query getEntities {
  entities(keys: ["*"], first: 4096) {
    edges {
      node {
        keys
        models {
          ... on Alert {
            x
            y
            alert
            __typename
          }
          ... on AppName {
            name
            system
            __typename
          }
          ... on App {
            name
            system
            __typename
          }
          ... on CoreActionsAddress {
            key
            value
            __typename
          }
          ... on Game {
            x
            y
            id
            state
            player1
            player2
            player1_commit
            player1_move
            player2_move
            started_timestamp
            __typename
          }
          ... on Permissions {
            allowing_app
            allowed_app
            permission {
              alert
              app
              color
              owner
              text
              timestamp
              action
              __typename
            }
            __typename
          }
          ... on Pixel {
            x
            y
            created_at
            updated_at
            alert
            app
            color
            owner
            text
            timestamp
            action
            __typename
          }
          ... on Player {
            player_id
            wins
            __typename
          }
          ... on Snake {
            length
            first_segment_id
            last_segment_id
            direction
            owner
            color
            text
            is_dying
            __typename
          }
          ... on SnakeSegment {
            id
            previous_id
            next_id
            x
            y
            pixel_original_color
            pixel_original_text
            __typename
          }
        }
      }
    }
  }
}
    `;
export const All_Filtered_EntitiesDocument = gql`
    query all_filtered_entities($first: Int, $xMin: u64, $xMax: u64, $yMin: u64, $yMax: u64) {
  pixelModels(
    first: $first
    where: {xGTE: $xMin, xLTE: $xMax, yGTE: $yMin, yLTE: $yMax}
  ) {
    edges {
      node {
        x
        y
        created_at
        updated_at
        alert
        app
        color
        owner
        text
        timestamp
        action
        __typename
      }
    }
  }
}
    `;
export const GetNeedsAttentionDocument = gql`
    query getNeedsAttention($first: Int, $address: ContractAddress) {
  pixelModels(first: $first, where: {ownerEQ: $address}) {
    edges {
      node {
        x
        y
        created_at
        updated_at
        alert
        app
        color
        owner
        text
        timestamp
        action
        __typename
      }
    }
  }
  alertModels(first: $first, where: {alert: true}) {
    edges {
      node {
        x
        y
        alert
        __typename
      }
    }
  }
}
    `;
export const AppsDocument = gql`
    query apps {
  appModels {
    edges {
      node {
        action
        name
        system
        __typename
      }
    }
  }
}
    `;

export type SdkFunctionWrapper = <T>(action: (requestHeaders?:Record<string, string>) => Promise<T>, operationName: string, operationType?: string) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = (action, _operationName, _operationType) => action();
const GetEntitiesDocumentString = print(GetEntitiesDocument);
const All_Filtered_EntitiesDocumentString = print(All_Filtered_EntitiesDocument);
const GetNeedsAttentionDocumentString = print(GetNeedsAttentionDocument);
const AppsDocumentString = print(AppsDocument);
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    getEntities(variables?: GetEntitiesQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: GetEntitiesQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<GetEntitiesQuery>(GetEntitiesDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'getEntities', 'query');
    },
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    all_filtered_entities(variables?: All_Filtered_EntitiesQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: All_Filtered_EntitiesQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<All_Filtered_EntitiesQuery>(All_Filtered_EntitiesDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'all_filtered_entities', 'query');
    },
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    getNeedsAttention(variables?: GetNeedsAttentionQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: GetNeedsAttentionQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<GetNeedsAttentionQuery>(GetNeedsAttentionDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'getNeedsAttention', 'query');
    },
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    apps(variables?: AppsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: AppsQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<AppsQuery>(AppsDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'apps', 'query');
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;