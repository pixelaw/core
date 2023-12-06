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

export type App = {
  __typename?: 'App';
  action?: Maybe<Scalars['felt252']['output']>;
  entity?: Maybe<World__Entity>;
  icon?: Maybe<Scalars['felt252']['output']>;
  manifest?: Maybe<Scalars['felt252']['output']>;
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
  Icon = 'ICON',
  Manifest = 'MANIFEST',
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
  icon?: InputMaybe<Scalars['felt252']['input']>;
  iconEQ?: InputMaybe<Scalars['felt252']['input']>;
  iconGT?: InputMaybe<Scalars['felt252']['input']>;
  iconGTE?: InputMaybe<Scalars['felt252']['input']>;
  iconLT?: InputMaybe<Scalars['felt252']['input']>;
  iconLTE?: InputMaybe<Scalars['felt252']['input']>;
  iconNEQ?: InputMaybe<Scalars['felt252']['input']>;
  manifest?: InputMaybe<Scalars['felt252']['input']>;
  manifestEQ?: InputMaybe<Scalars['felt252']['input']>;
  manifestGT?: InputMaybe<Scalars['felt252']['input']>;
  manifestGTE?: InputMaybe<Scalars['felt252']['input']>;
  manifestLT?: InputMaybe<Scalars['felt252']['input']>;
  manifestLTE?: InputMaybe<Scalars['felt252']['input']>;
  manifestNEQ?: InputMaybe<Scalars['felt252']['input']>;
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

export type Instruction = {
  __typename?: 'Instruction';
  entity?: Maybe<World__Entity>;
  instruction?: Maybe<Scalars['felt252']['output']>;
  selector?: Maybe<Scalars['felt252']['output']>;
  system?: Maybe<Scalars['ContractAddress']['output']>;
};

export type InstructionConnection = {
  __typename?: 'InstructionConnection';
  edges?: Maybe<Array<Maybe<InstructionEdge>>>;
  total_count: Scalars['Int']['output'];
};

export type InstructionEdge = {
  __typename?: 'InstructionEdge';
  cursor?: Maybe<Scalars['Cursor']['output']>;
  node?: Maybe<Instruction>;
};

export type InstructionOrder = {
  direction: OrderDirection;
  field: InstructionOrderField;
};

export enum InstructionOrderField {
  Instruction = 'INSTRUCTION',
  Selector = 'SELECTOR',
  System = 'SYSTEM'
}

export type InstructionWhereInput = {
  instruction?: InputMaybe<Scalars['felt252']['input']>;
  instructionEQ?: InputMaybe<Scalars['felt252']['input']>;
  instructionGT?: InputMaybe<Scalars['felt252']['input']>;
  instructionGTE?: InputMaybe<Scalars['felt252']['input']>;
  instructionLT?: InputMaybe<Scalars['felt252']['input']>;
  instructionLTE?: InputMaybe<Scalars['felt252']['input']>;
  instructionNEQ?: InputMaybe<Scalars['felt252']['input']>;
  selector?: InputMaybe<Scalars['felt252']['input']>;
  selectorEQ?: InputMaybe<Scalars['felt252']['input']>;
  selectorGT?: InputMaybe<Scalars['felt252']['input']>;
  selectorGTE?: InputMaybe<Scalars['felt252']['input']>;
  selectorLT?: InputMaybe<Scalars['felt252']['input']>;
  selectorLTE?: InputMaybe<Scalars['felt252']['input']>;
  selectorNEQ?: InputMaybe<Scalars['felt252']['input']>;
  system?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemGTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLT?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemLTE?: InputMaybe<Scalars['ContractAddress']['input']>;
  systemNEQ?: InputMaybe<Scalars['ContractAddress']['input']>;
};

export type ModelUnion = App | AppName | AppUser | CoreActionsAddress | Instruction | Permissions | Pixel | QueueItem | Snake | SnakeSegment;

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
  app?: Maybe<Scalars['bool']['output']>;
  color?: Maybe<Scalars['bool']['output']>;
  owner?: Maybe<Scalars['bool']['output']>;
  text?: Maybe<Scalars['bool']['output']>;
  timestamp?: Maybe<Scalars['bool']['output']>;
};

export type Pixel = {
  __typename?: 'Pixel';
  action?: Maybe<Scalars['felt252']['output']>;
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
  appModels?: Maybe<AppConnection>;
  appnameModels?: Maybe<AppNameConnection>;
  appuserModels?: Maybe<AppUserConnection>;
  coreactionsaddressModels?: Maybe<CoreActionsAddressConnection>;
  entities?: Maybe<World__EntityConnection>;
  entity: World__Entity;
  events?: Maybe<World__EventConnection>;
  instructionModels?: Maybe<InstructionConnection>;
  metadatas?: Maybe<World__MetadataConnection>;
  model: World__Model;
  models?: Maybe<World__ModelConnection>;
  permissionsModels?: Maybe<PermissionsConnection>;
  pixelModels?: Maybe<PixelConnection>;
  queueitemModels?: Maybe<QueueItemConnection>;
  snakeModels?: Maybe<SnakeConnection>;
  snakesegmentModels?: Maybe<SnakeSegmentConnection>;
  transaction: World__Transaction;
  transactions?: Maybe<World__TransactionConnection>;
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


export type World__QueryInstructionModelsArgs = {
  after?: InputMaybe<Scalars['Cursor']['input']>;
  before?: InputMaybe<Scalars['Cursor']['input']>;
  first?: InputMaybe<Scalars['Int']['input']>;
  last?: InputMaybe<Scalars['Int']['input']>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order?: InputMaybe<InstructionOrder>;
  where?: InputMaybe<InstructionWhereInput>;
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


export type GetEntitiesQuery = { __typename?: 'World__Query', entities?: { __typename?: 'World__EntityConnection', edges?: Array<{ __typename?: 'World__EntityEdge', node?: { __typename?: 'World__Entity', keys?: Array<string | null> | null, models?: Array<{ __typename: 'App', manifest?: any | null, icon?: any | null, action?: any | null, name?: any | null, system?: any | null } | { __typename: 'AppName', name?: any | null, system?: any | null } | { __typename: 'AppUser', action?: any | null, player?: any | null, system?: any | null } | { __typename: 'CoreActionsAddress', key?: any | null, value?: any | null } | { __typename?: 'Instruction' } | { __typename: 'Permissions', allowing_app?: any | null, allowed_app?: any | null, permission?: { __typename: 'Permissions_Permission', app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | null } | { __typename: 'Pixel', x?: any | null, y?: any | null, created_at?: any | null, updated_at?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | { __typename: 'QueueItem', id?: any | null, valid?: any | null } | { __typename?: 'Snake' } | { __typename?: 'SnakeSegment' } | null> | null } | null } | null> | null } | null };

export type All_Filtered_EntitiesQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
  xMin?: InputMaybe<Scalars['u64']['input']>;
  xMax?: InputMaybe<Scalars['u64']['input']>;
  yMin?: InputMaybe<Scalars['u64']['input']>;
  yMax?: InputMaybe<Scalars['u64']['input']>;
}>;


export type All_Filtered_EntitiesQuery = { __typename?: 'World__Query', pixelModels?: { __typename?: 'PixelConnection', edges?: Array<{ __typename?: 'PixelEdge', node?: { __typename: 'Pixel', x?: any | null, y?: any | null, created_at?: any | null, updated_at?: any | null, app?: any | null, color?: any | null, owner?: any | null, text?: any | null, timestamp?: any | null, action?: any | null } | null } | null> | null } | null };

export type AppsQueryVariables = Exact<{ [key: string]: never; }>;


export type AppsQuery = { __typename?: 'World__Query', appModels?: { __typename?: 'AppConnection', edges?: Array<{ __typename?: 'AppEdge', node?: { __typename: 'App', manifest?: any | null, icon?: any | null, action?: any | null, name?: any | null, system?: any | null } | null } | null> | null } | null };

export type AlertsQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
}>;


export type AlertsQuery = { __typename?: 'World__Query', events?: { __typename?: 'World__EventConnection', edges?: Array<{ __typename?: 'World__EventEdge', node?: { __typename?: 'World__Event', id?: string | null, keys?: Array<string | null> | null, data?: Array<string | null> | null, created_at?: any | null, transaction_hash?: string | null } | null } | null> | null } | null };

export type InstructionsQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
}>;


export type InstructionsQuery = { __typename?: 'World__Query', instructionModels?: { __typename?: 'InstructionConnection', edges?: Array<{ __typename?: 'InstructionEdge', node?: { __typename: 'Instruction', system?: any | null, selector?: any | null, instruction?: any | null } | null } | null> | null } | null };


export const GetEntitiesDocument = gql`
    query getEntities {
  entities(keys: ["*"], first: 4096) {
    edges {
      node {
        keys
        models {
          ... on App {
            manifest
            icon
            action
            name
            system
            __typename
          }
          ... on AppName {
            name
            system
            __typename
          }
          ... on AppUser {
            action
            player
            system
            __typename
          }
          ... on CoreActionsAddress {
            key
            value
            __typename
          }
          ... on Permissions {
            allowing_app
            allowed_app
            permission {
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
            app
            color
            owner
            text
            timestamp
            action
            __typename
          }
          ... on QueueItem {
            id
            valid
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
export const AppsDocument = gql`
    query apps {
  appModels {
    edges {
      node {
        manifest
        icon
        action
        name
        system
        __typename
      }
    }
  }
}
    `;
export const AlertsDocument = gql`
    query alerts($first: Int) {
  events(
    first: $first
    keys: ["0x4f01980329bc5de8cd181e4fb67fefefe583bd41f04365fa472ba112e7e5ef"]
  ) {
    edges {
      node {
        id
        keys
        data
        created_at
        transaction_hash
      }
    }
  }
}
    `;
export const InstructionsDocument = gql`
    query instructions($first: Int) {
  instructionModels(first: $first) {
    edges {
      node {
        system
        selector
        instruction
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
const AppsDocumentString = print(AppsDocument);
const AlertsDocumentString = print(AlertsDocument);
const InstructionsDocumentString = print(InstructionsDocument);
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
    apps(variables?: AppsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: AppsQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<AppsQuery>(AppsDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'apps', 'query');
    },
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    alerts(variables?: AlertsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: AlertsQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<AlertsQuery>(AlertsDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'alerts', 'query');
    },
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
    instructions(variables?: InstructionsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<{ data: InstructionsQuery; errors?: GraphQLError[]; extensions?: any; headers: Headers; status: number; }> {
        return withWrapper((wrappedRequestHeaders) => client.rawRequest<InstructionsQuery>(InstructionsDocumentString, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'instructions', 'query');
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;