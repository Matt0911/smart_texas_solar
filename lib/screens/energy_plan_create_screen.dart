import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:smart_texas_solar/models/energy_plan.dart';
import 'package:smart_texas_solar/models/energy_plan_custom_var.dart';
import 'package:smart_texas_solar/widgets/sts_drawer.dart';

final DateTime initialDate = DateTime.now();
final DateTime firstDate =
    DateTime.now().subtract(const Duration(days: 365 * 10));
final DateTime lastDate = DateTime.now().add(const Duration(days: 365 * 2));
final DateFormat _formatter = DateFormat('MM/dd/yyyy');

bool isNumeric(String? s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

bool isDate(String? s) {
  if (s == null) {
    return false;
  }
  try {
    _formatter.parse(s);
    return true;
  } catch (e) {
    return false;
  }
}

String? optionalNumberValidator(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  if (!isNumeric(value)) {
    return 'The entered value is not a number';
  }
  return null;
}

String? requiredNumberValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a number';
  }
  if (!isNumeric(value)) {
    return 'The entered value is not a number';
  }
  return null;
}

String? optionalDateValidator(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  if (!isDate(value)) {
    return 'The entered value is not a date';
  }
  return null;
}

void datePickerFormFieldOnTap(
    BuildContext context, TextEditingController ctl) async {
  // Below line stops keyboard from appearing
  FocusScope.of(context).requestFocus(FocusNode());

  var date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date != null) {
    // ctl.text = _formatter.format(date);
    ctl.value = TextEditingValue(text: _formatter.format(date));
  }
}

// Create a Form widget.
class CreateEnergyPlanForm extends StatefulWidget {
  const CreateEnergyPlanForm({super.key});

  @override
  CreateEnergyPlanFormState createState() {
    return CreateEnergyPlanFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class CreateEnergyPlanFormState extends State<CreateEnergyPlanForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController startDateCtl = TextEditingController();
  final TextEditingController endDateCtl = TextEditingController();

  final EnergyPlan _plan = EnergyPlan();

  List<EnergyPlanCustomVar> customVars = [];
  bool usesCustomEq = false;

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO add Plan Details header
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (val) => setState(() => _plan.name = val!),
              ),
              TextFormField(
                controller: startDateCtl,
                onTap: () => datePickerFormFieldOnTap(context, startDateCtl),
                decoration: const InputDecoration(labelText: 'Start Date'),
                validator: optionalDateValidator,
                onSaved: (val) => setState(() => _plan.startDate =
                    val == null || val.isEmpty ? null : _formatter.parse(val)),
              ),
              TextFormField(
                controller: endDateCtl,
                onTap: () => datePickerFormFieldOnTap(context, endDateCtl),
                decoration: const InputDecoration(labelText: 'End Date'),
                validator: optionalDateValidator,
                onSaved: (val) => setState(() => _plan.endDate =
                    val == null || val.isEmpty ? null : _formatter.parse(val)),
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Connection Fee (cf)'),
                validator: requiredNumberValidator,
                onSaved: (val) =>
                    setState(() => _plan.connectionFee = double.parse(val!)),
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Delivery Charge (d)'),
                validator: requiredNumberValidator,
                onSaved: (val) =>
                    setState(() => _plan.deliveryCharge = double.parse(val!)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'kWh Charge (k)'),
                validator: requiredNumberValidator,
                onSaved: (val) =>
                    setState(() => _plan.kwhCharge = double.parse(val!)),
              ),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Solar Buyback Rate (sbr)'),
                validator: optionalNumberValidator,
                onSaved: (val) => setState(
                    () => _plan.solarBuybackRate = double.tryParse(val!) ?? 0),
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Base Monthly Charge (b)'),
                validator: optionalNumberValidator,
                onSaved: (val) => setState(
                    () => _plan.baseCharge = double.tryParse(val!) ?? 0),
              ),
              // TODO: show provided vars c and s and time related?
              const Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Text(
                  'Standard Equation: ${EnergyPlan.standardEquation}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              CheckboxListTile(
                title: const Text('Use Custom Equation'),
                value: usesCustomEq,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.only(top: 16),
                onChanged: (newValue) =>
                    setState(() => usesCustomEq = newValue!),
              ),
              usesCustomEq
                  ? TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Custom Equation'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the desired custom equation';
                        }
                        try {
                          EnergyPlan.validateCustomEq(value, customVars);
                        } on StateError catch (e) {
                          return e.message;
                        } catch (e) {
                          return 'Not Valid';
                        }
                        return null;
                      },
                      onSaved: (val) =>
                          setState(() => _plan.customEquation = val ?? ''),
                    )
                  : const SizedBox(),
              // TODO add Custom Calculation header
              ...customVars.map((e) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a name for this variable';
                                  }
                                  return null;
                                },
                                onChanged: (val) =>
                                    setState(() => e.name = val),
                              ),
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Value'),
                                validator: requiredNumberValidator,
                                onChanged: (val) => setState(
                                    () => e.value = double.tryParse(val) ?? 0),
                              ),
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Symbol'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a symbol to use for this variable';
                                  }
                                  return null;
                                },
                                onChanged: (val) =>
                                    setState(() => e.symbol = val),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                customVars.remove(e);
                              });
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
              // TODO group this button with above visually
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      customVars.add(EnergyPlanCustomVar());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Custom Variable'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Validate returns true if the form is valid, or false otherwise.
                      final form = _formKey.currentState;
                      if (form!.validate()) {
                        form.save();
                        _plan.customVars = customVars;
                        Navigator.of(context).pop(_plan);
                      }
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnergyPlanCreateScreen extends ConsumerWidget {
  static const String routeName = '/energy-plan-create-screen';

  const EnergyPlanCreateScreen({super.key});

  @override
  Widget build(context, ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Energy Plan'),
      ),
      drawer: const STSDrawer(),
      body: const CreateEnergyPlanForm(),
    );
  }
}
