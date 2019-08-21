import org.apache.flink.api.common.state.MapState;
import org.apache.flink.api.common.state.MapStateDescriptor;
import org.apache.flink.api.common.typeinfo.TypeHint;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.java.tuple.Tuple0;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.contrib.streaming.state.RocksDBStateBackend;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.CheckpointConfig;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.streaming.api.functions.source.RichSourceFunction;
import org.apache.flink.util.Collector;

import java.util.Random;

public class Main {

	public static void main(String[] args) throws Exception {

		final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
		env.setStateBackend(new RocksDBStateBackend("hdfs://namenode1:9820/fjob/checkpoints", true));
		env.enableCheckpointing(1000);
		CheckpointConfig cpcfg = env.getCheckpointConfig();
		cpcfg.setCheckpointTimeout(30_000); // Default of 10 minutes requires too large checkpoints.
		cpcfg.setFailOnCheckpointingErrors(false);


		DataStream<Integer> triggers = env.addSource(new RichSourceFunction<Integer>() {
			@Override
			public void run(SourceContext<Integer> sourceContext) throws Exception {
				for (int i = 28; i <= 33; i++) {
					try {
						Thread.sleep(5000);
					} catch(InterruptedException ignored) {
					}
					for (int j = 0; j < 8; j++)
						sourceContext.collect(i - 3);
				}
				System.out.println("No more messages.");
				while (true)
					try {
						Thread.sleep(60000);
					} catch (InterruptedException ignored) {
					}
			}

			@Override
			public void cancel() {
				System.err.println("No, why!");
			}
		});

		SingleOutputStreamOperator<Tuple0> out = triggers.keyBy(x -> x).process(new KeyedProcessFunction<Integer, Integer, Tuple0>() {
			private transient MapState<Integer, byte[]> bstate;
			@Override
			public void open(Configuration config) {
				MapStateDescriptor<Integer, byte[]> descriptor =
						new MapStateDescriptor<>("bloop",
								TypeInformation.of(new TypeHint<Integer>() {}),
								TypeInformation.of(new TypeHint<byte[]>() {})
						);
				bstate = getRuntimeContext().getMapState(descriptor);
			}

			@Override
			public void processElement(Integer exp, Context context, Collector<Tuple0> collector) throws Exception {
				long size = 1L << exp;
				System.out.println("" + size + " B");
				int chunk = 8192; // Java can't even. jni-RocksDB couldn't either. And my RAM doesn't want to.
				for (int i = 0; size > 0; i++, size -= chunk) {
					byte[] bloo = new byte[chunk];
					new Random().nextBytes(bloo);
					bstate.put(i, bloo);
				}
			}
		});

		out.print();

		// execute program
		env.execute("5 seconds");
	}
}
