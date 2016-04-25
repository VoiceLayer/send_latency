# SendLatency

**Measure message passing latency under differnt load conditions**

## HowTo

* Clone repository
* Run tests using mix

Sender processes send 10 byte messages at a rate of 5 messages per second. The receivers track the latency per message and once finished convey the results to the collector process which display the statistics.

For example:

```bash
elixir --erl "+K true +A 100 +P 5000000" -S mix SendLatency --clients 110000 --threshold 500

Summary
=======
Got 110000 results
Max Latency = 486ms
Quantize:
  0ms = 358886
  1ms = 482995
 10ms = 1435546
 50ms = 1942669
100ms = 1389904
500ms = 0
   1s = 0
```

SendLatency parameters:
* *clients* : The number of senders and receiver processes
* *duration* : The duration of the test
* *threshold* : Provide latency quantization details when longer than (0, 1, 10, 5, 100, 500, 1000ms) 
