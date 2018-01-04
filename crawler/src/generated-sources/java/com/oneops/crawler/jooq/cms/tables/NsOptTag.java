/*
 * This file is generated by jOOQ.
*/
package com.oneops.crawler.jooq.cms.tables;


import com.oneops.crawler.jooq.cms.Indexes;
import com.oneops.crawler.jooq.cms.Keys;
import com.oneops.crawler.jooq.cms.Kloopzcm;
import com.oneops.crawler.jooq.cms.tables.records.NsOptTagRecord;

import java.util.Arrays;
import java.util.List;

import javax.annotation.Generated;

import org.jooq.Field;
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
public class NsOptTag extends TableImpl<NsOptTagRecord> {

    private static final long serialVersionUID = 222049552;

    /**
     * The reference instance of <code>kloopzcm.ns_opt_tag</code>
     */
    public static final NsOptTag NS_OPT_TAG = new NsOptTag();

    /**
     * The class holding records for this type
     */
    @Override
    public Class<NsOptTagRecord> getRecordType() {
        return NsOptTagRecord.class;
    }

    /**
     * The column <code>kloopzcm.ns_opt_tag.tag_id</code>.
     */
    public final TableField<NsOptTagRecord, Long> TAG_ID = createField("tag_id", org.jooq.impl.SQLDataType.BIGINT.nullable(false), this, "");

    /**
     * The column <code>kloopzcm.ns_opt_tag.tag</code>.
     */
    public final TableField<NsOptTagRecord, String> TAG = createField("tag", org.jooq.impl.SQLDataType.VARCHAR(64).nullable(false), this, "");

    /**
     * Create a <code>kloopzcm.ns_opt_tag</code> table reference
     */
    public NsOptTag() {
        this(DSL.name("ns_opt_tag"), null);
    }

    /**
     * Create an aliased <code>kloopzcm.ns_opt_tag</code> table reference
     */
    public NsOptTag(String alias) {
        this(DSL.name(alias), NS_OPT_TAG);
    }

    /**
     * Create an aliased <code>kloopzcm.ns_opt_tag</code> table reference
     */
    public NsOptTag(Name alias) {
        this(alias, NS_OPT_TAG);
    }

    private NsOptTag(Name alias, Table<NsOptTagRecord> aliased) {
        this(alias, aliased, null);
    }

    private NsOptTag(Name alias, Table<NsOptTagRecord> aliased, Field<?>[] parameters) {
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
        return Arrays.<Index>asList(Indexes.NS_OPT_TAG_IDX, Indexes.TAG_ID);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public UniqueKey<NsOptTagRecord> getPrimaryKey() {
        return Keys.TAG_ID;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<UniqueKey<NsOptTagRecord>> getKeys() {
        return Arrays.<UniqueKey<NsOptTagRecord>>asList(Keys.TAG_ID);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public NsOptTag as(String alias) {
        return new NsOptTag(DSL.name(alias), this);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public NsOptTag as(Name alias) {
        return new NsOptTag(alias, this);
    }

    /**
     * Rename this table
     */
    @Override
    public NsOptTag rename(String name) {
        return new NsOptTag(DSL.name(name), null);
    }

    /**
     * Rename this table
     */
    @Override
    public NsOptTag rename(Name name) {
        return new NsOptTag(name, null);
    }
}
