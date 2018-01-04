/*
 * This file is generated by jOOQ.
*/
package com.oneops.crawler.jooq.cms.tables;


import com.oneops.crawler.jooq.cms.Indexes;
import com.oneops.crawler.jooq.cms.Keys;
import com.oneops.crawler.jooq.cms.Kloopzcm;
import com.oneops.crawler.jooq.cms.tables.records.MdClassAttributesRecord;

import java.sql.Timestamp;
import java.util.Arrays;
import java.util.List;

import javax.annotation.Generated;

import org.jooq.Field;
import org.jooq.ForeignKey;
import org.jooq.Index;
import org.jooq.Name;
import org.jooq.Schema;
import org.jooq.Table;
import org.jooq.TableField;
import org.jooq.UniqueKey;
import org.jooq.impl.DSL;
import org.jooq.impl.TableImpl;


/**
 * This class is generated by jOOQ.
 */
@Generated(
    value = {
        "http://www.jooq.org",
        "jOOQ version:3.10.0"
    },
    comments = "This class is generated by jOOQ"
)
@SuppressWarnings({ "all", "unchecked", "rawtypes" })
public class MdClassAttributes extends TableImpl<MdClassAttributesRecord> {

    private static final long serialVersionUID = -1942452863;

    /**
     * The reference instance of <code>kloopzcm.md_class_attributes</code>
     */
    public static final MdClassAttributes MD_CLASS_ATTRIBUTES = new MdClassAttributes();

    /**
     * The class holding records for this type
     */
    @Override
    public Class<MdClassAttributesRecord> getRecordType() {
        return MdClassAttributesRecord.class;
    }

    /**
     * The column <code>kloopzcm.md_class_attributes.attribute_id</code>.
     */
    public final TableField<MdClassAttributesRecord, Integer> ATTRIBUTE_ID = createField("attribute_id", org.jooq.impl.SQLDataType.INTEGER.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.class_id</code>.
     */
    public final TableField<MdClassAttributesRecord, Integer> CLASS_ID = createField("class_id", org.jooq.impl.SQLDataType.INTEGER.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.attribute_name</code>.
     */
    public final TableField<MdClassAttributesRecord, String> ATTRIBUTE_NAME = createField("attribute_name", org.jooq.impl.SQLDataType.VARCHAR(200).nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.data_type</code>.
     */
    public final TableField<MdClassAttributesRecord, String> DATA_TYPE = createField("data_type", org.jooq.impl.SQLDataType.VARCHAR(64).nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.is_mandatory</code>.
     */
    public final TableField<MdClassAttributesRecord, Boolean> IS_MANDATORY = createField("is_mandatory", org.jooq.impl.SQLDataType.BOOLEAN.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.is_inheritable</code>.
     */
    public final TableField<MdClassAttributesRecord, Boolean> IS_INHERITABLE = createField("is_inheritable", org.jooq.impl.SQLDataType.BOOLEAN.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.is_encrypted</code>.
     */
    public final TableField<MdClassAttributesRecord, Boolean> IS_ENCRYPTED = createField("is_encrypted", org.jooq.impl.SQLDataType.BOOLEAN.nullable(false).defaultValue(org.jooq.impl.DSL.field("false", org.jooq.impl.SQLDataType.BOOLEAN)), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.force_on_dependent</code>.
     */
    public final TableField<MdClassAttributesRecord, Boolean> FORCE_ON_DEPENDENT = createField("force_on_dependent", org.jooq.impl.SQLDataType.BOOLEAN.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.default_value</code>.
     */
    public final TableField<MdClassAttributesRecord, String> DEFAULT_VALUE = createField("default_value", org.jooq.impl.SQLDataType.CLOB, this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.value_format</code>.
     */
    public final TableField<MdClassAttributesRecord, String> VALUE_FORMAT = createField("value_format", org.jooq.impl.SQLDataType.CLOB, this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.description</code>.
     */
    public final TableField<MdClassAttributesRecord, String> DESCRIPTION = createField("description", org.jooq.impl.SQLDataType.CLOB, this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.created</code>.
     */
    public final TableField<MdClassAttributesRecord, Timestamp> CREATED = createField("created", org.jooq.impl.SQLDataType.TIMESTAMP.nullable(false).defaultValue(org.jooq.impl.DSL.field("now()", org.jooq.impl.SQLDataType.TIMESTAMP)), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.updated</code>.
     */
    public final TableField<MdClassAttributesRecord, Timestamp> UPDATED = createField("updated", org.jooq.impl.SQLDataType.TIMESTAMP.nullable(false).defaultValue(org.jooq.impl.DSL.field("now()", org.jooq.impl.SQLDataType.TIMESTAMP)), this, "");

    /**
     * The column <code>kloopzcm.md_class_attributes.is_immutable</code>.
     */
    public final TableField<MdClassAttributesRecord, Boolean> IS_IMMUTABLE = createField("is_immutable", org.jooq.impl.SQLDataType.BOOLEAN.nullable(false).defaultValue(org.jooq.impl.DSL.field("false", org.jooq.impl.SQLDataType.BOOLEAN)), this, "");

    /**
     * Create a <code>kloopzcm.md_class_attributes</code> table reference
     */
    public MdClassAttributes() {
        this(DSL.name("md_class_attributes"), null);
    }

    /**
     * Create an aliased <code>kloopzcm.md_class_attributes</code> table reference
     */
    public MdClassAttributes(String alias) {
        this(DSL.name(alias), MD_CLASS_ATTRIBUTES);
    }

    /**
     * Create an aliased <code>kloopzcm.md_class_attributes</code> table reference
     */
    public MdClassAttributes(Name alias) {
        this(alias, MD_CLASS_ATTRIBUTES);
    }

    private MdClassAttributes(Name alias, Table<MdClassAttributesRecord> aliased) {
        this(alias, aliased, null);
    }

    private MdClassAttributes(Name alias, Table<MdClassAttributesRecord> aliased, Field<?>[] parameters) {
        super(alias, null, aliased, parameters, "");
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Schema getSchema() {
        return Kloopzcm.KLOOPZCM;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<Index> getIndexes() {
        return Arrays.<Index>asList(Indexes.MD_CLASS_ATTR_NAME_IDX, Indexes.MD_CLASS_ATTRIBUTES_CL_IDX, Indexes.MD_CLASS_ATTRIBUTES_PK);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public UniqueKey<MdClassAttributesRecord> getPrimaryKey() {
        return Keys.MD_CLASS_ATTRIBUTES_PK;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<UniqueKey<MdClassAttributesRecord>> getKeys() {
        return Arrays.<UniqueKey<MdClassAttributesRecord>>asList(Keys.MD_CLASS_ATTRIBUTES_PK);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<ForeignKey<MdClassAttributesRecord, ?>> getReferences() {
        return Arrays.<ForeignKey<MdClassAttributesRecord, ?>>asList(Keys.MD_CLASS_ATTRIBUTES__MD_CLASS_ATTRIBUTES_CLID_FK);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public MdClassAttributes as(String alias) {
        return new MdClassAttributes(DSL.name(alias), this);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public MdClassAttributes as(Name alias) {
        return new MdClassAttributes(alias, this);
    }

    /**
     * Rename this table
     */
    @Override
    public MdClassAttributes rename(String name) {
        return new MdClassAttributes(DSL.name(name), null);
    }

    /**
     * Rename this table
     */
    @Override
    public MdClassAttributes rename(Name name) {
        return new MdClassAttributes(name, null);
    }
}
