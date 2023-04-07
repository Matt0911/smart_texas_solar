import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  DateTime? currentSelectedDate;
  try {
    currentSelectedDate = _formatter.parse(ctl.text);
  } catch (e) {
    // this should only happen if current text isnt valid date
  }

  // TODO: allow removing date
  var date = await showDatePicker(
    context: context,
    initialDate: currentSelectedDate ?? initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date != null) {
    // ctl.text = _formatter.format(date);
    ctl.value = TextEditingValue(text: _formatter.format(date));
  }
}

// Create a Form widget.
class EditEnergyPlanForm extends StatefulWidget {
  final EnergyPlan plan;
  final bool initialUsesCustomEq;
  final List<EnergyPlanCustomVar> customVars;
  final TextEditingController startDateCtl;
  final TextEditingController endDateCtl;
  EditEnergyPlanForm({super.key, required this.plan})
      : customVars = [...plan.customVars],
        initialUsesCustomEq = plan.usesCustomEq,
        startDateCtl = TextEditingController(
          text:
              plan.startDate == null ? '' : _formatter.format(plan.startDate!),
        ),
        endDateCtl = TextEditingController(
          text: plan.endDate == null ? '' : _formatter.format(plan.endDate!),
        );

  @override
  EditEnergyPlanFormState createState() {
    return EditEnergyPlanFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class EditEnergyPlanFormState extends State<EditEnergyPlanForm> {
  final _formKey = GlobalKey<FormState>();
  late bool usesCustomEq;

  @override
  void initState() {
    super.initState();
    usesCustomEq = widget.initialUsesCustomEq;
  }

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
              const Heading(text: 'Plan Details'),
              TextFormField(
                initialValue: widget.plan.name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (val) => setState(() => widget.plan.name = val!),
              ),
              TextFormField(
                controller: widget.startDateCtl,
                onTap: () =>
                    datePickerFormFieldOnTap(context, widget.startDateCtl),
                decoration: const InputDecoration(labelText: 'Start Date'),
                validator: optionalDateValidator,
                onSaved: (val) => setState(() => widget.plan.startDate =
                    val == null || val.isEmpty ? null : _formatter.parse(val)),
              ),
              TextFormField(
                controller: widget.endDateCtl,
                onTap: () =>
                    datePickerFormFieldOnTap(context, widget.endDateCtl),
                decoration: const InputDecoration(labelText: 'End Date'),
                validator: optionalDateValidator,
                onSaved: (val) => setState(() => widget.plan.endDate =
                    val == null || val.isEmpty ? null : _formatter.parse(val)),
              ),
              TextFormField(
                initialValue: widget.plan.connectionFee.toString(),
                decoration:
                    const InputDecoration(labelText: 'Connection Fee (cf)'),
                validator: requiredNumberValidator,
                onSaved: (val) => setState(
                    () => widget.plan.connectionFee = double.parse(val!)),
              ),
              TextFormField(
                initialValue: widget.plan.deliveryCharge.toString(),
                decoration:
                    const InputDecoration(labelText: 'Delivery Charge (d)'),
                validator: requiredNumberValidator,
                onSaved: (val) => setState(
                    () => widget.plan.deliveryCharge = double.parse(val!)),
              ),
              TextFormField(
                initialValue: widget.plan.kwhCharge.toString(),
                decoration: const InputDecoration(labelText: 'kWh Charge (k)'),
                validator: requiredNumberValidator,
                onSaved: (val) =>
                    setState(() => widget.plan.kwhCharge = double.parse(val!)),
              ),
              TextFormField(
                initialValue: widget.plan.solarBuybackRate == 0
                    ? null
                    : widget.plan.solarBuybackRate.toString(),
                decoration: const InputDecoration(
                    labelText: 'Solar Buyback Rate (sbr)'),
                validator: optionalNumberValidator,
                onSaved: (val) => setState(() =>
                    widget.plan.solarBuybackRate = double.tryParse(val!) ?? 0),
              ),
              TextFormField(
                initialValue: widget.plan.baseCharge == 0
                    ? null
                    : widget.plan.baseCharge.toString(),
                decoration:
                    const InputDecoration(labelText: 'Base Monthly Charge (b)'),
                validator: optionalNumberValidator,
                onSaved: (val) => setState(
                    () => widget.plan.baseCharge = double.tryParse(val!) ?? 0),
              ),
              const Heading(text: 'Provided Variables'),
              const Text('Consumption for Billing Period (c)'),
              const Text('Solar Surplus for Billing Period (s)'),
              const Heading(
                  text: 'Standard Equation: ${EnergyPlan.standardEquation}'),
              CheckboxListTile(
                title: const Text('Use Custom Equation'),
                value: usesCustomEq,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.only(top: 16),
                onChanged: (newValue) =>
                    setState(() => usesCustomEq = newValue!),
              ),
              usesCustomEq
                  ? TextFormField(
                      initialValue: widget.plan.customEquation,
                      decoration:
                          const InputDecoration(labelText: 'Custom Equation'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the desired custom equation';
                        }
                        try {
                          EnergyPlan.validateCustomEq(value, widget.customVars);
                        } on StateError catch (e) {
                          return e.message;
                        } catch (e) {
                          return 'Not Valid';
                        }
                        return null;
                      },
                      onSaved: (val) => setState(
                          () => widget.plan.customEquation = val ?? ''),
                    )
                  : const SizedBox(),
              ...widget.customVars.map((e) {
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
                                initialValue: e.name,
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
                                initialValue: e.value.toString(),
                                decoration:
                                    const InputDecoration(labelText: 'Value'),
                                validator: requiredNumberValidator,
                                onChanged: (val) => setState(
                                    () => e.value = double.tryParse(val) ?? 0),
                              ),
                              TextFormField(
                                initialValue: e.symbol,
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
                                widget.customVars.remove(e);
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
                      widget.customVars.add(EnergyPlanCustomVar());
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
                        widget.plan.customVars = widget.customVars;
                        widget.plan.usesCustomEq = usesCustomEq;
                        Navigator.of(context).pop(widget.plan);
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

class Heading extends StatelessWidget {
  final String text;

  const Heading({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class EnergyPlanEditScreen extends ConsumerWidget {
  static const String routeName = '/energy-plan-edit-screen';

  const EnergyPlanEditScreen({super.key});

  @override
  Widget build(context, ref) {
    final plan = ModalRoute.of(context)!.settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(plan == null ? 'Create New Energy Plan' : 'Edit Energy Plan'),
      ),
      drawer: const STSDrawer(),
      body: EditEnergyPlanForm(
        plan: (plan ?? EnergyPlan()) as EnergyPlan,
      ),
    );
  }
}
