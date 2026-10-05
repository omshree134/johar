import '../../../data/models/ar_task.dart';
import 'choose_exit_task.dart';
import 'extinguish_task.dart';
import 'find_hazards_task.dart';
import 'gas_test_task.dart';
import 'select_set_task.dart';
import 'sequence_task.dart';
import 'task_controller.dart';

TaskController createTaskController(ArTask task) => switch (task.type) {
      ArTaskType.findHazards => FindHazardsTask(task),
      ArTaskType.chooseExit => ChooseExitTask(task),
      ArTaskType.extinguish => ExtinguishTask(task),
      ArTaskType.gasTest => GasTestTask(task),
      ArTaskType.selectSet => SelectSetTask(task),
      ArTaskType.sequence => SequenceTask(task),
    };
