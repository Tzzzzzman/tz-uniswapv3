-include .env

anvil :; anvil --code-size-limit 50000

deploy :; forge script script/DeployDevelopment.s.sol:DeployDevelopment --broadcast --fork-url http://localhost:8545 --private-key $(PRIVATE_KEY)  --code-size-limit 50000


$ params='{"from":"0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266","to":"0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512","data":"0x70a08231000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"}'
$ curl -X POST -H 'Content-Type: application/json' \
  --data '{"id":1,"jsonrpc":"2.0","method":"eth_call","params":['"$params"',"latest"]}' \
  http://127.0.0.1:8545

{"jsonrpc":"2.0","id":1,"result":"0x00000000000000000000000000000000000000000000011153ce5e56cf880000"}
