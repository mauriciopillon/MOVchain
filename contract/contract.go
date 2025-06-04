package main

import (
	"fmt"
	"encoding/json"
	"time"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for interacting with the ledger
type SmartContract struct {
	contractapi.Contract
}

// Asset struct to hold asset data
type Asset struct {
	ID            string  `json:"ID"`
	Name          string  `json:"name"`
	GreenIndex    string  `json:"greenIndex"`
	Owner         string  `json:"owner"`
	CreatedAt     string  `json:"createdAt"`
	UpdatedAt     string  `json:"updatedAt"`
}

// Transaction struct to hold transaction data
type Transaction struct {
	ID        string `json:"ID"`
	From      string `json:"from"`
	To        string `json:"to"`
	AssetID   string `json:"assetID"`
	Date      string `json:"date"`
	TxHash    string `json:"txHash"`
}

// CreateAsset creates a new asset
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, ID string, name string, greenIndex string, owner string) error {
	// Check if asset already exists
	exists, err := s.AssetExists(ctx, ID)
	if err != nil {
		return fmt.Errorf("failed to check if asset exists: %v", err)
	}
	if exists {
		return fmt.Errorf("asset %s already exists", ID)
	}

	currentTime := time.Now().UTC().Format(time.RFC3339)
	asset := Asset{
		ID:         ID,
		Name:       name,
		GreenIndex: greenIndex,
		Owner:      owner,
		CreatedAt:  currentTime,
		UpdatedAt:  currentTime,
	}

	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return fmt.Errorf("failed to marshal asset: %v", err)
	}

	return ctx.GetStub().PutState("ASSET_"+ID, assetJSON)
}

// GetAsset returns a specific asset by ID
func (s *SmartContract) GetAsset(ctx contractapi.TransactionContextInterface, ID string) (*Asset, error) {
	assetJSON, err := ctx.GetStub().GetState("ASSET_" + ID)
	if err != nil {
		return nil, fmt.Errorf("failed to read asset from world state: %v", err)
	}
	if assetJSON == nil {
		return nil, fmt.Errorf("asset %s does not exist", ID)
	}

	var asset Asset
	err = json.Unmarshal(assetJSON, &asset)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal asset: %v", err)
	}

	return &asset, nil
}

// GetAllAssets returns all assets
func (s *SmartContract) GetAllAssets(ctx contractapi.TransactionContextInterface) ([]Asset, error) {
	queryResults, err := ctx.GetStub().GetStateByRange("ASSET_", "ASSET_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get assets: %v", err)
	}
	defer queryResults.Close()

	var assets []Asset
	for queryResults.HasNext() {
		result, err := queryResults.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate query results: %v", err)
		}

		var asset Asset
		err = json.Unmarshal(result.Value, &asset)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal asset: %v", err)
		}
		assets = append(assets, asset)
	}

	return assets, nil
}

// TransferAsset transfers ownership of an asset and creates a transaction record
func (s *SmartContract) TransferAsset(ctx contractapi.TransactionContextInterface, assetID string, newOwner string, transactionID string) error {
	// Get the asset
	asset, err := s.GetAsset(ctx, assetID)
	if err != nil {
		return fmt.Errorf("failed to get asset: %v", err)
	}

	oldOwner := asset.Owner
	
	// Update asset owner
	asset.Owner = newOwner
	asset.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return fmt.Errorf("failed to marshal asset: %v", err)
	}

	err = ctx.GetStub().PutState("ASSET_"+assetID, assetJSON)
	if err != nil {
		return fmt.Errorf("failed to update asset: %v", err)
	}

	// Create transaction record
	txHash := ctx.GetStub().GetTxID()
	transaction := Transaction{
		ID:      transactionID,
		From:    oldOwner,
		To:      newOwner,
		AssetID: assetID,
		Date:    time.Now().UTC().Format(time.RFC3339),
		TxHash:  txHash,
	}

	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	return ctx.GetStub().PutState("TX_"+transactionID, transactionJSON)
}

// CreateTransaction creates a standalone transaction record
func (s *SmartContract) CreateTransaction(ctx contractapi.TransactionContextInterface, ID string, from string, to string, assetID string) error {
	// Check if transaction already exists
	exists, err := s.TransactionExists(ctx, ID)
	if err != nil {
		return fmt.Errorf("failed to check if transaction exists: %v", err)
	}
	if exists {
		return fmt.Errorf("transaction %s already exists", ID)
	}

	// Verify that the asset exists
	_, err = s.GetAsset(ctx, assetID)
	if err != nil {
		return fmt.Errorf("asset %s does not exist: %v", assetID, err)
	}

	txHash := ctx.GetStub().GetTxID()
	transaction := Transaction{
		ID:      ID,
		From:    from,
		To:      to,
		AssetID: assetID,
		Date:    time.Now().UTC().Format(time.RFC3339),
		TxHash:  txHash,
	}

	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	return ctx.GetStub().PutState("TX_"+ID, transactionJSON)
}

// GetTransaction returns a specific transaction by ID
func (s *SmartContract) GetTransaction(ctx contractapi.TransactionContextInterface, ID string) (*Transaction, error) {
	transactionJSON, err := ctx.GetStub().GetState("TX_" + ID)
	if err != nil {
		return nil, fmt.Errorf("failed to read transaction from world state: %v", err)
	}
	if transactionJSON == nil {
		return nil, fmt.Errorf("transaction %s does not exist", ID)
	}

	var transaction Transaction
	err = json.Unmarshal(transactionJSON, &transaction)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal transaction: %v", err)
	}

	return &transaction, nil
}

// GetAllTransactions returns all transactions
func (s *SmartContract) GetAllTransactions(ctx contractapi.TransactionContextInterface) ([]Transaction, error) {
	queryResults, err := ctx.GetStub().GetStateByRange("TX_", "TX_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get transactions: %v", err)
	}
	defer queryResults.Close()

	var transactions []Transaction
	for queryResults.HasNext() {
		result, err := queryResults.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate query results: %v", err)
		}

		var transaction Transaction
		err = json.Unmarshal(result.Value, &transaction)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal transaction: %v", err)
		}
		transactions = append(transactions, transaction)
	}

	return transactions, nil
}

// GetTransactionsByAsset returns all transactions for a specific asset
func (s *SmartContract) GetTransactionsByAsset(ctx contractapi.TransactionContextInterface, assetID string) ([]Transaction, error) {
	allTransactions, err := s.GetAllTransactions(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get all transactions: %v", err)
	}

	var assetTransactions []Transaction
	for _, tx := range allTransactions {
		if tx.AssetID == assetID {
			assetTransactions = append(assetTransactions, tx)
		}
	}

	return assetTransactions, nil
}

// GetAssetHistory returns the transaction history for an asset (supply chain traceability)
func (s *SmartContract) GetAssetHistory(ctx contractapi.TransactionContextInterface, assetID string) ([]Transaction, error) {
	return s.GetTransactionsByAsset(ctx, assetID)
}

// AssetExists checks if an asset exists
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, ID string) (bool, error) {
	assetJSON, err := ctx.GetStub().GetState("ASSET_" + ID)
	if err != nil {
		return false, fmt.Errorf("failed to read asset from world state: %v", err)
	}

	return assetJSON != nil, nil
}

// TransactionExists checks if a transaction exists
func (s *SmartContract) TransactionExists(ctx contractapi.TransactionContextInterface, ID string) (bool, error) {
	transactionJSON, err := ctx.GetStub().GetState("TX_" + ID)
	if err != nil {
		return false, fmt.Errorf("failed to read transaction from world state: %v", err)
	}

	return transactionJSON != nil, nil
}

// UpdateAsset updates an existing asset (only owner and greenIndex can be updated)
func (s *SmartContract) UpdateAsset(ctx contractapi.TransactionContextInterface, ID string, greenIndex string, owner string) error {
	asset, err := s.GetAsset(ctx, ID)
	if err != nil {
		return fmt.Errorf("failed to get asset: %v", err)
	}

	asset.GreenIndex = greenIndex
	asset.Owner = owner
	asset.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return fmt.Errorf("failed to marshal asset: %v", err)
	}

	return ctx.GetStub().PutState("ASSET_"+ID, assetJSON)
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting chaincode: %s", err.Error())
	}
}
