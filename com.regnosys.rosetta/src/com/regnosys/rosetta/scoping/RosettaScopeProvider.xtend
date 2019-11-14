/*
 * generated by Xtext 2.10.0
 */
package com.regnosys.rosetta.scoping

import com.google.common.base.Predicate
import com.google.inject.Inject
import com.regnosys.rosetta.RosettaExtensions
import com.regnosys.rosetta.generator.util.RosettaFunctionExtensions
import com.regnosys.rosetta.rosetta.RosettaBinaryOperation
import com.regnosys.rosetta.rosetta.RosettaChoiceRule
import com.regnosys.rosetta.rosetta.RosettaClass
import com.regnosys.rosetta.rosetta.RosettaEnumValueReference
import com.regnosys.rosetta.rosetta.RosettaExternalClass
import com.regnosys.rosetta.rosetta.RosettaExternalRegularAttribute
import com.regnosys.rosetta.rosetta.RosettaFeatureCall
import com.regnosys.rosetta.rosetta.RosettaGroupByExpression
import com.regnosys.rosetta.rosetta.RosettaGroupByFeatureCall
import com.regnosys.rosetta.rosetta.RosettaModel
import com.regnosys.rosetta.rosetta.RosettaRegularAttribute
import com.regnosys.rosetta.rosetta.RosettaWorkflowRule
import com.regnosys.rosetta.rosetta.simple.AnnotationRef
import com.regnosys.rosetta.rosetta.simple.Attribute
import com.regnosys.rosetta.rosetta.simple.Condition
import com.regnosys.rosetta.rosetta.simple.Data
import com.regnosys.rosetta.rosetta.simple.Function
import com.regnosys.rosetta.rosetta.simple.FunctionDispatch
import com.regnosys.rosetta.rosetta.simple.Operation
import com.regnosys.rosetta.rosetta.simple.Segment
import com.regnosys.rosetta.rosetta.simple.ShortcutDeclaration
import com.regnosys.rosetta.types.RClassType
import com.regnosys.rosetta.types.RDataType
import com.regnosys.rosetta.types.REnumType
import com.regnosys.rosetta.types.RFeatureCallType
import com.regnosys.rosetta.types.RRecordType
import com.regnosys.rosetta.types.RType
import com.regnosys.rosetta.types.RosettaTypeProvider
import com.regnosys.rosetta.utils.RosettaConfigExtension
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.FilteringScope
import org.eclipse.xtext.scoping.impl.ImportedNamespaceAwareLocalScopeProvider
import org.eclipse.xtext.scoping.impl.SimpleScope

import static com.regnosys.rosetta.rosetta.RosettaPackage.Literals.*
import static com.regnosys.rosetta.rosetta.simple.SimplePackage.Literals.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class RosettaScopeProvider extends ImportedNamespaceAwareLocalScopeProvider {

	@Inject RosettaTypeProvider typeProvider
	@Inject extension RosettaExtensions
	@Inject extension RosettaConfigExtension configs
	@Inject extension RosettaFunctionExtensions

	override getScope(EObject context, EReference reference) {
		switch reference {
			case ROSETTA_GROUP_BY_EXPRESSION__ATTRIBUTE:
				if (context instanceof RosettaGroupByFeatureCall) {
					val featureCall = context.call
					if (featureCall instanceof RosettaFeatureCall) {
						val receiverType = typeProvider.getRType(featureCall.feature)
						val featureScope = receiverType.createFeatureScope
						if (featureScope !== null)
							return featureScope
					}
					return IScope.NULLSCOPE
				} else if (context instanceof RosettaGroupByExpression) {
					val container = context.eContainer
					if (container instanceof RosettaGroupByFeatureCall) {
						val featureCall = container.call
						if (featureCall instanceof RosettaFeatureCall) {
							val receiverType = typeProvider.getRType(featureCall.feature)
							val featureScope = receiverType.createFeatureScope
							if (featureScope !== null)
								return featureScope
						}
					}
					else if (container instanceof RosettaGroupByExpression) {
						val parentType = typeProvider.getRType(container.attribute)
						val featureScope = parentType.createFeatureScope
							if (featureScope !== null)
								return featureScope
					}
					return IScope.NULLSCOPE
				}
			case ROSETTA_FEATURE_CALL__FEATURE: {
				if (context instanceof RosettaFeatureCall) {
					val receiverType = typeProvider.getRType(context.receiver)
					val featureScope = receiverType.createFeatureScope
					var allPosibilities = newArrayList
					
					if (featureScope!==null) {
						allPosibilities.addAll(featureScope.allElements);
					}
					//if an attribute has metafields then then the meta names are valid in a feature call e.g. -> currency -> scheme
					val receiver = context.receiver;
					if (receiver instanceof RosettaFeatureCall) {
						val feature = receiver.feature
						switch(feature) {
							RosettaRegularAttribute:  {
								val metas = feature.metaTypes;
								if (metas !== null && !metas.isEmpty) {
									val metaScope = Scopes.scopeFor(metas)
									allPosibilities.addAll(metaScope.allElements);
								}
							}
							Attribute: {
								val metas = feature.metaAnnotations.map[it.attribute?.name].filterNull.toList
								if (metas !== null && !metas.isEmpty) {
									allPosibilities.addAll(configs.findMetaTypes(feature).filter[
										metas.contains(it.name.toString)
									]);
								}
							}
						}
					}
					return new SimpleScope(allPosibilities)
				}
				return IScope.NULLSCOPE
			}
			case OPERATION__ASSIGN_ROOT: {
				if (context instanceof Operation) {
					val outAndAliases = newArrayList
					val out = getOutput(context.function)
					if (out !== null) {
						outAndAliases.add(out)
					}
					outAndAliases.addAll(context.function.shortcuts)
					return Scopes.scopeFor(outAndAliases)
				}
				return IScope.NULLSCOPE
			}
			case SEGMENT__ATTRIBUTE: {
				switch (context) {
					Operation: {
						val receiverType = typeProvider.getRType(context.assignRoot)
						val featureScope = receiverType.createFeatureScope
						if (featureScope !== null) {
							return featureScope;
						}
						return IScope.NULLSCOPE
					}
					Segment: {
						val prev = context.prev
						if (prev !== null) {
							if (prev.attribute !== null && !prev.attribute.eIsProxy) {
								val receiverType = typeProvider.getRType(prev.attribute)
								val featureScope = receiverType.createFeatureScope
								if (featureScope !== null) {
									return featureScope;
								}
								return IScope.NULLSCOPE
							}
						}
						if (context.eContainer instanceof Operation) {
							return getScope(context.eContainer, reference)
						}
						return defaultScope(context, reference)
					}
					default:
						return defaultScope(context, reference)
				}
			}
			case ROSETTA_CALLABLE_CALL__CALLABLE: {
				if (context instanceof RosettaWorkflowRule) {
					val parent = context.root?.parent
					if (parent instanceof Data) {
						val allClasses = parent.allSuperTypes
						val scope = Scopes.scopeFor(allClasses)
						return scope
					}else if(parent instanceof RosettaClass) {
						val allClasses = parent.allSuperTypes
						val scope = Scopes.scopeFor(allClasses)
						return scope
					}
				} else if (context instanceof Operation) {
					val function = context.function
					val inputsAndOutputs = newArrayList
					if(!function.inputs.nullOrEmpty)
						inputsAndOutputs.addAll(function.inputs)
					if(function.output!==null)
						inputsAndOutputs.add(function.output)
					return Scopes.scopeFor(inputsAndOutputs)
				} else {
					val funcContainer = EcoreUtil2.getContainerOfType(context, Function)
					if(funcContainer !== null) {
						return filteredScope(getParentScope(context, reference, IScope.NULLSCOPE), [
							descr | descr.EClass !== ROSETTA_CLASS && descr.EClass !== DATA
						])
					}
					
				}
				return defaultScope(context, reference)
			}
			case ROSETTA_CALLABLE_WITH_ARGS_CALL__CALLABLE: {
				return filteredScope(defaultScope(context, reference), [EClass !== FUNCTION_DISPATCH])
			}
			case ROSETTA_ENUM_VALUE_REFERENCE__VALUE: {
				if (context instanceof RosettaEnumValueReference) {
					return Scopes.scopeFor(context.enumeration.allEnumValues)
				}
				return IScope.NULLSCOPE
			}
			case ROSETTA_CHOICE_RULE__THIS_ONE: {
				if (context instanceof RosettaChoiceRule) {
					val choiceScope = context.scope
					return Scopes.scopeFor(choiceScope.allAttributes)
				}
				return IScope.NULLSCOPE
			}
			case ROSETTA_CHOICE_RULE__THAT_ONES: {
				if (context instanceof RosettaChoiceRule) {
					val choiceScope = context.scope
					return Scopes.scopeFor(choiceScope.allAttributes)
				}
				return IScope.NULLSCOPE
			}
			case ROSETTA_WORKFLOW_RULE__COMMON_IDENTIFIER:
				if (context instanceof RosettaWorkflowRule) {
					val parent = context.root?.parent
					if (parent instanceof Data) {
						return Scopes.scopeFor(parent.allAttributes)
					} else if(parent instanceof RosettaClass)
						return Scopes.scopeFor(parent.allAttributes)
				}
			case ROSETTA_ENUM_VALUE_REFERENCE__ENUMERATION: {
				if (context instanceof RosettaEnumValueReference
					|| context instanceof FunctionDispatch
					|| context instanceof RosettaBinaryOperation) {
					return defaultScope(context, reference)
				}
				return IScope.NULLSCOPE
			}
			case ROSETTA_EXTERNAL_REGULAR_ATTRIBUTE__ATTRIBUTE_REF: {
				if (context instanceof RosettaExternalRegularAttribute) {
					val classRef = (context.eContainer as RosettaExternalClass).classRef
					if(classRef instanceof Data)
						return Scopes.scopeFor(classRef.allAttributes)
					else if(classRef instanceof RosettaClass)
						return Scopes.scopeFor(classRef.allAttributes)
				}
				return IScope.NULLSCOPE
			}
			case ANNOTATION_REF__ATTRIBUTE: {
				if (context instanceof AnnotationRef) {
					val annoRef = context.annotation
					return Scopes.scopeFor(annoRef.attributes)
				}
				return IScope.NULLSCOPE
			}
			case FUNCTION_DISPATCH__ATTRIBUTE: {
				if(context instanceof FunctionDispatch) {
					return Scopes.scopeFor(getInputs(context))
				}
				return IScope.NULLSCOPE
			}
			case CONSTRAINT__ATTRIBUTES: {
				return context.getParentScope(reference, IScope.NULLSCOPE)
			}
		}
		defaultScope(context, reference)
	}
	
	override protected getImplicitImports(boolean ignoreCase) {
		#[createImportedNamespaceResolver("com.rosetta.model.*", ignoreCase)]
	}
	
	override protected internalGetImportedNamespaceResolvers(EObject context, boolean ignoreCase) {
		return if (context instanceof RosettaModel) {
			return #[
				doCreateImportNormalizer(getQualifiedNameConverter.toQualifiedName(context.name), true, ignoreCase)
			]
		} else
			emptyList
	}
	
	private def IScope defaultScope(EObject object, EReference reference) {
		filteredScope(super.getScope(object,reference), [it.EClass !== FUNCTION_DISPATCH])
	}
	
	private def IScope getParentScope(EObject object, EReference reference, IScope outer) {
		if (object === null) {
			return IScope.NULLSCOPE
		}
		val parentScope = getParentScope(object.eContainer, reference, outer)
		switch (object) {
			Data: {
				return Scopes.scopeFor(object.allAttributes, outer)
			}
			Function: {
				val features = newArrayList
				features.addAll(getInputs(object))
				val out = getOutput(object)
				if (out !== null)
					features.add(getOutput(object))
				features.addAll(object.shortcuts)
				return Scopes.scopeFor(features, filteredScope(parentScope)[ descr |
					descr.EClass == ROSETTA_ENUMERATION
				])
			}
			ShortcutDeclaration: {
				filteredScope(parentScope, [descr|
					descr.qualifiedName.toString != object.name // TODO use qnames
				])
			}
			Condition: {
				filteredScope(parentScope, [ descr |
					object.isPostCondition || descr.EObjectOrProxy.eContainingFeature !== FUNCTION__OUTPUT
				])
			}
			RosettaModel:
				defaultScope(object, reference)
			default:
				parentScope
		}
	}
	
	def private IScope filteredScope(IScope scope, Predicate<IEObjectDescription> filter) {
		new FilteringScope(scope,filter)
	}

	private def IScope createFeatureScope(RType receiverType) {
		switch receiverType {
			RClassType:
				Scopes.scopeFor(receiverType.clazz.allAttributes)
			RDataType:
				Scopes.scopeFor(receiverType.data.allAttributes)
			REnumType:
				Scopes.scopeFor(receiverType.enumeration.allEnumValues)
			RRecordType:
				Scopes.scopeFor(receiverType.record.features)
			RFeatureCallType:
				receiverType.featureType.createFeatureScope
			default:
				null
		}
	}
}